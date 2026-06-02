import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image_lib;
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await _loadCameras();
  runApp(SignRecognitionApp(cameras: cameras));
}

Future<List<CameraDescription>> _loadCameras() async {
  try {
    return availableCameras();
  } catch (_) {
    return const <CameraDescription>[];
  }
}

class SignRecognitionApp extends StatelessWidget {
  const SignRecognitionApp({
    super.key,
    required this.cameras,
    this.autoCheckServer = true,
  });

  final List<CameraDescription> cameras;
  final bool autoCheckServer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Language Recognition V2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Color(0xFFE6E6E6),
          selectionHandleColor: Colors.black,
        ),
      ),
      home: RecognitionScreen(
        cameras: cameras,
        autoCheckServer: autoCheckServer,
      ),
    );
  }
}

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({
    super.key,
    required this.cameras,
    this.autoCheckServer = true,
  });

  final List<CameraDescription> cameras;
  final bool autoCheckServer;

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen>
    with WidgetsBindingObserver {
  static const _frameInterval = Duration(milliseconds: 900);
  static const _requestTimeout = Duration(seconds: 18);
  static const _modelServerUrl = 'http://192.168.1.208:5000';

  CameraController? _cameraController;
  final http.Client _httpClient = http.Client();
  Timer? _snapshotTimer;

  String _letter = '--';
  double _confidence = 0;
  bool _handDetected = false;
  bool _cameraReady = false;
  bool _checkingServer = false;
  bool _serverReady = false;
  bool _recognizing = false;
  bool _liveDetectionEnabled = true;
  bool _streamingImages = false;
  bool _processingFrame = false;
  DateTime _lastFrameSent = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveErrors = 0;
  String _status = 'Preparando camara...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    if (widget.autoCheckServer) {
      _checkServer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_stopLiveDetection(updateStatus: false));
      return;
    }

    if (state == AppLifecycleState.resumed && _liveDetectionEnabled) {
      unawaited(_startLiveDetection());
    }
  }

  Uri _endpoint(String path) {
    return Uri.parse('$_modelServerUrl$path');
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      if (!mounted) return;
      setState(() {
        _status = 'No se encontro una camara disponible.';
      });
      return;
    }

    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      if (!mounted) return;
      setState(() {
        _status = 'Activa el permiso de camara para usar la verificacion.';
      });
      return;
    }

    final camera = widget.cameras.firstWhere(
      (item) => item.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _status = 'Camara activa. Esperando backend en linea.';
      });
      await _startLiveDetection();
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _status =
            'No se pudo iniciar la camara: ${error.description ?? error.code}';
      });
    }
  }

  Future<void> _checkServer() async {
    if (_checkingServer) return;

    setState(() {
      _checkingServer = true;
      _serverReady = false;
      _status = 'Comprobando backend...';
    });

    try {
      final response = await http
          .get(_endpoint('/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final modelsLoaded = data['models_loaded'] == true;

      setState(() {
        _serverReady = modelsLoaded;
        _status = modelsLoaded
            ? 'Backend en linea. Detectando en tiempo real.'
            : 'Backend conectado. El modelo aun esta cargando.';
      });
    } catch (error) {
      setState(() {
        _serverReady = false;
        _status = 'Backend fuera de linea.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingServer = false;
        });
      }
    }
  }

  Future<void> _startLiveDetection() async {
    final controller = _cameraController;
    if (!_cameraReady ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    try {
      await controller.startImageStream(_onCameraImage);
      if (!mounted) return;
      setState(() {
        _streamingImages = true;
        _status = _serverReady
            ? 'Detectando en tiempo real...'
            : 'Camara activa. Esperando backend en linea.';
      });
    } on CameraException catch (error) {
      _startSnapshotFallback(
        'Stream no disponible: ${error.description ?? error.code}',
      );
    } on UnimplementedError catch (error) {
      _startSnapshotFallback(error.message ?? 'Stream no implementado');
    } on UnsupportedError catch (error) {
      _startSnapshotFallback(error.message ?? 'Stream no soportado');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _streamingImages = false;
        _status = 'No se pudo activar la deteccion en vivo: $error';
      });
    }
  }

  Future<void> _stopLiveDetection({bool updateStatus = true}) async {
    final controller = _cameraController;
    final hasSnapshotFallback = _snapshotTimer != null;
    if ((controller == null || !controller.value.isStreamingImages) &&
        !hasSnapshotFallback) {
      return;
    }

    _snapshotTimer?.cancel();
    _snapshotTimer = null;

    try {
      if (controller != null && controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } on CameraException catch (_) {
      // La camara puede estar cerrandose por ciclo de vida de la app.
    }

    if (!mounted) return;
    setState(() {
      _streamingImages = false;
      _recognizing = false;
      if (updateStatus) {
        _status = 'Deteccion en vivo pausada. La camara sigue activa.';
      }
    });
  }

  void _startSnapshotFallback(String reason) {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(_frameInterval, (_) {
      if (_beginRecognition()) {
        unawaited(_recognizeSnapshot());
      }
    });

    if (!mounted) return;
    setState(() {
      _streamingImages = true;
      _status = _serverReady
          ? 'Detectando en tiempo real...'
          : 'Camara activa. Esperando backend en linea.';
    });

    if (reason.isNotEmpty) {
      debugPrint('Usando capturas periodicas para deteccion en vivo. $reason');
    }
  }

  void _onCameraImage(CameraImage image) {
    if (!_liveDetectionEnabled ||
        !_serverReady ||
        _processingFrame ||
        !_cameraReady) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastFrameSent) < _frameInterval) return;
    _lastFrameSent = now;

    if (!_beginRecognition()) return;
    unawaited(_recognizeFrame(image));
  }

  bool _beginRecognition() {
    if (!_liveDetectionEnabled ||
        !_serverReady ||
        _processingFrame ||
        !_cameraReady) {
      return false;
    }

    _processingFrame = true;

    if (mounted) {
      setState(() {
        _recognizing = true;
      });
    }

    return true;
  }

  Future<void> _recognizeFrame(CameraImage image) async {
    try {
      final jpegBytes = _cameraImageToJpeg(image);
      if (jpegBytes == null) {
        throw UnsupportedError(
            'Formato de camara no soportado: ${image.format.group}');
      }

      await _submitJpegBytes(jpegBytes);
    } catch (error) {
      _handleRecognitionError(error);
    } finally {
      _finishRecognition();
    }
  }

  Future<void> _recognizeSnapshot() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _finishRecognition();
      return;
    }

    XFile? picture;

    try {
      picture = await controller.takePicture();
      final jpegBytes = await File(picture.path).readAsBytes();
      await _submitJpegBytes(jpegBytes);
    } catch (error) {
      _handleRecognitionError(error);
    } finally {
      if (picture != null) {
        try {
          await File(picture.path).delete();
        } catch (_) {
          // Algunas plataformas limpian automaticamente las capturas temporales.
        }
      }
      _finishRecognition();
    }
  }

  Future<void> _submitJpegBytes(Uint8List jpegBytes) async {
    final request = http.MultipartRequest('POST', _endpoint('/recognize'));
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        jpegBytes,
        filename: 'frame.jpg',
      ),
    );

    final streamedResponse =
        await _httpClient.send(request).timeout(_requestTimeout);
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw HttpException('HTTP ${streamedResponse.statusCode}: $responseBody');
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final confidenceValue = data['confidence'];
    final confidence =
        confidenceValue is num ? confidenceValue.toDouble() : 0.0;
    final handDetected = data['hand_detected'] == true;
    final letter = (data['letter'] ?? '--').toString();

    _consecutiveErrors = 0;
    if (!mounted) return;
    setState(() {
      _letter = letter.isEmpty ? '--' : letter;
      _confidence = confidence.clamp(0.0, 1.0);
      _handDetected = handDetected;
      _serverReady = true;
      _status = handDetected
          ? 'Detectando en tiempo real...'
          : 'Camara activa. No se detecta una mano clara.';
    });
  }

  void _handleRecognitionError(Object error) {
    _consecutiveErrors += 1;
    if (mounted && _consecutiveErrors >= 3) {
      setState(() {
        _letter = '--';
        _confidence = 0;
        _handDetected = false;
        _serverReady = false;
        _status = 'Backend fuera de linea.';
      });
    }
  }

  void _finishRecognition() {
    _processingFrame = false;
    if (mounted) {
      setState(() {
        _recognizing = false;
      });
    }
  }

  Uint8List? _cameraImageToJpeg(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.jpeg) {
      if (cameraImage.planes.isEmpty) return null;
      return cameraImage.planes.first.bytes;
    }

    final image = switch (cameraImage.format.group) {
      ImageFormatGroup.yuv420 => _yuv420ToImage(cameraImage),
      ImageFormatGroup.bgra8888 => _bgra8888ToImage(cameraImage),
      _ => null,
    };
    if (image == null) return null;

    final oriented = _orientFrame(image);
    return Uint8List.fromList(image_lib.encodeJpg(oriented, quality: 72));
  }

  image_lib.Image _yuv420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final image = image_lib.Image(width: width, height: height);
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (var y = 0; y < height; y++) {
      final yRowOffset = y * yPlane.bytesPerRow;
      final uvRowOffset = (y >> 1) * uPlane.bytesPerRow;

      for (var x = 0; x < width; x++) {
        final yValue = yPlane.bytes[yRowOffset + x];
        final uvOffset = uvRowOffset + (x >> 1) * uvPixelStride;
        final uValue = uPlane.bytes[uvOffset];
        final vValue = vPlane.bytes[uvOffset];

        final r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round()
                .clamp(0, 255);
        final b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  image_lib.Image _bgra8888ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final image = image_lib.Image(width: width, height: height);
    final plane = cameraImage.planes.first;
    final pixelStride = plane.bytesPerPixel ?? 4;

    for (var y = 0; y < height; y++) {
      final rowOffset = y * plane.bytesPerRow;

      for (var x = 0; x < width; x++) {
        final pixelOffset = rowOffset + x * pixelStride;
        final b = plane.bytes[pixelOffset];
        final g = plane.bytes[pixelOffset + 1];
        final r = plane.bytes[pixelOffset + 2];

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  image_lib.Image _orientFrame(image_lib.Image image) {
    final orientation = _cameraController?.description.sensorOrientation ?? 0;

    return switch (orientation) {
      90 => image_lib.copyRotate(image, angle: 90),
      180 => image_lib.copyRotate(image, angle: 180),
      270 => image_lib.copyRotate(image, angle: 270),
      _ => image,
    };
  }

  void _toggleLiveDetection() {
    setState(() {
      _liveDetectionEnabled = !_liveDetectionEnabled;
    });

    if (_liveDetectionEnabled) {
      unawaited(_startLiveDetection());
      if (_serverReady) {
        setState(() {
          _status = 'Detectando en tiempo real...';
        });
      }
    } else {
      unawaited(_stopLiveDetection());
    }
  }

  void _clearResult() {
    setState(() {
      _letter = '--';
      _confidence = 0;
      _handDetected = false;
      _status = _serverReady
          ? 'Resultado limpio. Detectando en tiempo real...'
          : 'Resultado limpio. Backend fuera de linea.';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _snapshotTimer?.cancel();
    final controller = _cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      unawaited(controller.stopImageStream());
    }
    _httpClient.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            if (wide) {
              return Row(
                children: [
                  Expanded(child: _CameraPane(controller: _cameraController)),
                  SizedBox(
                    width: 380,
                    child: _ControlPanel(
                      letter: _letter,
                      confidence: _confidence,
                      handDetected: _handDetected,
                      status: _status,
                      serverReady: _serverReady,
                      checkingServer: _checkingServer,
                      recognizing: _recognizing,
                      cameraReady: _cameraReady,
                      liveEnabled: _liveDetectionEnabled,
                      streamingImages: _streamingImages,
                      onCheckServer: _checkServer,
                      onToggleLive: _toggleLiveDetection,
                      onClear: _clearResult,
                    ),
                  ),
                ],
              );
            }

            final panelHeight = constraints.maxHeight < 680
                ? constraints.maxHeight * 0.52
                : 360.0;

            return Column(
              children: [
                Expanded(child: _CameraPane(controller: _cameraController)),
                SizedBox(
                  height: panelHeight,
                  child: _ControlPanel(
                    letter: _letter,
                    confidence: _confidence,
                    handDetected: _handDetected,
                    status: _status,
                    serverReady: _serverReady,
                    checkingServer: _checkingServer,
                    recognizing: _recognizing,
                    cameraReady: _cameraReady,
                    liveEnabled: _liveDetectionEnabled,
                    streamingImages: _streamingImages,
                    onCheckServer: _checkServer,
                    onToggleLive: _toggleLiveDetection,
                    onClear: _clearResult,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CameraPane extends StatelessWidget {
  const _CameraPane({required this.controller});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    final ready = camera != null && camera.value.isInitialized;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            Center(
              child: AspectRatio(
                aspectRatio: camera.value.aspectRatio,
                child: CameraPreview(camera),
              ),
            )
          else
            const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          const Positioned.fill(child: _FocusFrame()),
          const Positioned(
            left: 20,
            top: 18,
            child: _CameraBadge(),
          ),
        ],
      ),
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'SIGN LANGUAGE RECOGNITION V2',
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.letter,
    required this.confidence,
    required this.handDetected,
    required this.status,
    required this.serverReady,
    required this.checkingServer,
    required this.recognizing,
    required this.cameraReady,
    required this.liveEnabled,
    required this.streamingImages,
    required this.onCheckServer,
    required this.onToggleLive,
    required this.onClear,
  });

  final String letter;
  final double confidence;
  final bool handDetected;
  final String status;
  final bool serverReady;
  final bool checkingServer;
  final bool recognizing;
  final bool cameraReady;
  final bool liveEnabled;
  final bool streamingImages;
  final VoidCallback onCheckServer;
  final VoidCallback onToggleLive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final liveLabel = liveEnabled
        ? recognizing
            ? 'DETECTANDO'
            : 'EN VIVO'
        : 'REANUDAR';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.black, width: 1)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verificacion ASL',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Modelo: sign_language_recognition_v2',
              style: TextStyle(fontSize: 12, color: Color(0xFF606060)),
            ),
            const SizedBox(height: 20),
            _ResultBox(
              letter: letter,
              confidence: confidence,
              handDetected: handDetected,
            ),
            const SizedBox(height: 16),
            _StatusBox(
              serverReady: serverReady,
              checkingServer: checkingServer,
              liveEnabled: liveEnabled,
              streamingImages: streamingImages,
              status: status,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: checkingServer ? null : onCheckServer,
                    icon: checkingServer
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: const Text('VERIFICAR'),
                    style: _outlinedStyle(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Limpiar resultado',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: cameraReady ? onToggleLive : null,
              icon: recognizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      liveEnabled
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 19,
                    ),
              label: Text(liveLabel),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                disabledForegroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      side: const BorderSide(color: Colors.black),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({
    required this.letter,
    required this.confidence,
    required this.handDetected,
  });

  final String letter;
  final double confidence;
  final bool handDetected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESULTADO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF606060),
                letterSpacing: 0.9,
              ),
            ),
            Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 78,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: confidence,
                minHeight: 9,
                backgroundColor: const Color(0xFFE8E8E8),
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(confidence * 100).round()}% confianza',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF606060)),
                ),
                Text(
                  handDetected ? 'MANO DETECTADA' : 'SIN MANO',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.serverReady,
    required this.checkingServer,
    required this.liveEnabled,
    required this.streamingImages,
    required this.status,
  });

  final bool serverReady;
  final bool checkingServer;
  final bool liveEnabled;
  final bool streamingImages;
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = checkingServer
        ? 'COMPROBANDO'
        : serverReady
            ? 'BACKEND EN LINEA'
            : 'BACKEND OFFLINE';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        border: Border.all(color: const Color(0xFFD0D0D0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  serverReady
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 17,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              status,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusFrame extends StatelessWidget {
  const _FocusFrame();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FocusFramePainter());
  }
}

class _FocusFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final inset = size.shortestSide * 0.16;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    const corner = 42.0;

    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(0, corner), paint);
    canvas.drawLine(
        rect.topRight, rect.topRight - const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(0, corner), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft - const Offset(0, corner), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight - const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight - const Offset(0, corner), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

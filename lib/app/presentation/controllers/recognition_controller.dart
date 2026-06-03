import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/speech_service.dart';
import '../../domain/entities/recognition_result.dart';
import '../../domain/repositories/recognition_repository.dart';

/// Controlador GetX de la pantalla de reconocimiento.
///
/// Concentra toda la logica de estado (camara, conexion al servidor, modo de
/// deteccion) y la expone de forma reactiva con variables `.obs`, de modo que
/// las vistas pueden ser `StatelessWidget` y reconstruirse solo con `Obx`.
class RecognitionController extends GetxController with WidgetsBindingObserver {
  RecognitionController(this._repository, this._speech);

  final RecognitionRepository _repository;
  final SpeechService _speech;

  // --- Estado reactivo ------------------------------------------------------
  final Rx<RecognitionResult> result = RecognitionResult.empty.obs;
  final RxString status = 'Preparando camara...'.obs;
  final RxString word = ''.obs;
  final RxBool cameraReady = false.obs;
  final RxBool serverReady = false.obs;
  final RxBool checkingServer = false.obs;
  final RxBool recognizing = false.obs;
  final RxBool liveEnabled = true.obs;

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  Timer? _captureTimer;
  bool _processing = false;
  bool _disposed = false;
  int _consecutiveErrors = 0;

  // Estabilidad para fijar letras en la palabra.
  String? _candidate;
  int _streak = 0;
  int _cooldown = 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([checkServer(), _initCamera()]);
    if (_disposed) return;
    if (serverReady.value && cameraReady.value && liveEnabled.value) {
      _startLiveDetection();
    }
  }

  // --- Servidor -------------------------------------------------------------
  Future<void> checkServer() async {
    if (checkingServer.value) return;
    checkingServer.value = true;
    status.value = 'Comprobando servidor...';
    try {
      await _repository.init();
      serverReady.value = _repository.isReady;
      status.value = serverReady.value
          ? 'Servidor en linea. Detectando en tiempo real.'
          : 'Servidor conectado, modelos aun cargando.';
    } catch (_) {
      serverReady.value = false;
      status.value = 'Servidor fuera de linea.';
    } finally {
      if (!_disposed) checkingServer.value = false;
    }
  }

  // --- Camara ---------------------------------------------------------------
  Future<void> _initCamera() async {
    final cameras = await _availableCameras();
    if (cameras.isEmpty) {
      status.value = 'No se encontro una camara disponible.';
      return;
    }

    final granted = await Permission.camera.request();
    if (!granted.isGranted) {
      status.value = 'Activa el permiso de camara para usar la verificacion.';
      return;
    }

    final camera = cameras.firstWhere(
      (item) => item.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      cameraReady.value = true;
      update(); // refresca el preview (GetBuilder)
    } on CameraException catch (error) {
      status.value =
          'No se pudo iniciar la camara: ${error.description ?? error.code}';
    }
  }

  Future<List<CameraDescription>> _availableCameras() async {
    try {
      return await availableCameras();
    } catch (_) {
      return const <CameraDescription>[];
    }
  }

  // --- Deteccion continua (modo captura) ------------------------------------
  void _startLiveDetection() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(AppConstants.captureInterval, (_) {
      _captureAndRecognize();
    });
    if (serverReady.value) {
      status.value = 'Detectando en tiempo real...';
    }
  }

  void _stopLiveDetection() {
    _captureTimer?.cancel();
    _captureTimer = null;
    recognizing.value = false;
  }

  Future<void> _captureAndRecognize() async {
    final controller = _cameraController;
    if (_processing ||
        !serverReady.value ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    _processing = true;
    recognizing.value = true;

    XFile? shot;
    try {
      shot = await controller.takePicture();
      final bytes = await File(shot.path).readAsBytes();
      final recognized = await _repository.recognizeJpeg(bytes);
      if (_disposed) return;
      _consecutiveErrors = 0;
      result.value = recognized;
      _buildWord(recognized);
      status.value = recognized.handDetected
          ? 'Detectando en tiempo real...'
          : 'Camara activa. No se detecta una mano clara.';
    } catch (_) {
      _consecutiveErrors += 1;
      if (!_disposed && _consecutiveErrors >= 3) {
        serverReady.value = false;
        result.value = RecognitionResult.empty;
        status.value = 'Servidor fuera de linea.';
      }
    } finally {
      if (shot != null) {
        unawaited(File(shot.path).delete().catchError((_) => File(shot!.path)));
      }
      _processing = false;
      if (!_disposed) recognizing.value = false;
    }
  }

  // --- Construccion de palabra ----------------------------------------------
  /// Fija una letra en la palabra solo cuando se detecta de forma estable
  /// durante varias capturas seguidas, con un cooldown para no repetirla.
  void _buildWord(RecognitionResult r) {
    if (_cooldown > 0) _cooldown -= 1;

    if (!r.handDetected || r.letter == '--' || r.letter.isEmpty) {
      _candidate = null;
      _streak = 0;
      return;
    }

    if (r.letter == _candidate) {
      _streak += 1;
    } else {
      _candidate = r.letter;
      _streak = 1;
    }

    if (_streak >= AppConstants.wordStabilityCaptures && _cooldown == 0) {
      word.value += r.letter;
      _cooldown = AppConstants.wordCooldownCaptures;
      _streak = 0;
      _candidate = null;
    }
  }

  /// Agrega un espacio y pronuncia la palabra recien terminada.
  void addSpace() {
    final current = word.value;
    if (current.isEmpty || current.endsWith(' ')) return;
    final lastWord = current.split(' ').last;
    if (lastWord.isNotEmpty) {
      unawaited(_speech.speak(lastWord));
    }
    word.value = '$current ';
  }

  /// Borra la ultima letra.
  void backspace() {
    final current = word.value;
    if (current.isNotEmpty) {
      word.value = current.substring(0, current.length - 1);
    }
  }

  /// Limpia toda la frase.
  void clearWord() {
    word.value = '';
    _candidate = null;
    _streak = 0;
    _cooldown = 0;
  }

  /// Pronuncia toda la frase formada.
  void speakWord() {
    unawaited(_speech.speak(word.value));
  }

  // --- Acciones de UI -------------------------------------------------------
  void toggleLive() {
    liveEnabled.value = !liveEnabled.value;
    if (liveEnabled.value) {
      _startLiveDetection();
    } else {
      _stopLiveDetection();
      status.value = 'Deteccion pausada. La camara sigue activa.';
    }
  }

  void clearResult() {
    result.value = RecognitionResult.empty;
    status.value = serverReady.value
        ? 'Resultado limpio. Detectando en tiempo real...'
        : 'Resultado limpio. Servidor fuera de linea.';
  }

  // --- Ciclo de vida --------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopLiveDetection();
    } else if (state == AppLifecycleState.resumed && liveEnabled.value) {
      _startLiveDetection();
    }
  }

  @override
  void onClose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _repository.dispose();
    unawaited(_speech.stop());
    super.onClose();
  }
}

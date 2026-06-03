import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

/// Fuente de datos que delega el reconocimiento a un servidor REST
/// (Flask + MediaPipe + SigLIP2). El servidor recorta la mano antes de
/// clasificar, por eso la prediccion es precisa.
class AslRestDataSource {
  final http.Client _client = http.Client();
  bool _ready = false;

  bool get isReady => _ready;

  Uri _endpoint(String path) => Uri.parse('${AppConstants.serverUrl}$path');

  /// Comprueba que el servidor este en linea y con los modelos cargados.
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(_endpoint(AppConstants.healthPath))
          .timeout(AppConstants.healthTimeout);
      if (response.statusCode != 200) {
        _ready = false;
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _ready = data['models_loaded'] == true;
      return _ready;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  /// Envia la imagen JPEG al servidor y devuelve la prediccion.
  Future<({String letter, double confidence, bool handDetected})> recognizeJpeg(
    Uint8List jpegBytes,
  ) async {
    final request =
        http.MultipartRequest('POST', _endpoint(AppConstants.recognizePath));
    request.files.add(
      http.MultipartFile.fromBytes('image', jpegBytes, filename: 'frame.jpg'),
    );

    final streamed = await _client.send(request).timeout(
          AppConstants.requestTimeout,
        );
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw http.ClientException('HTTP ${streamed.statusCode}: $body');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final confidenceValue = data['confidence'];
    final confidence =
        confidenceValue is num ? confidenceValue.toDouble() : 0.0;
    final letter = (data['letter'] ?? '--').toString();

    _ready = true;
    return (
      letter: letter.isEmpty ? '--' : letter,
      confidence: confidence.clamp(0.0, 1.0),
      handDetected: data['hand_detected'] == true,
    );
  }

  void close() => _client.close();
}

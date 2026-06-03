import 'package:flutter_tts/flutter_tts.dart';

import '../constants/app_constants.dart';

/// Servicio de sintesis de voz (Text-To-Speech).
///
/// Envuelve `flutter_tts` para pronunciar la palabra formada con las señas.
/// Es un servicio de plataforma (salida), inyectado por GetX y usado por el
/// controlador de presentacion.
class SpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage(AppConstants.ttsLanguage);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  /// Pronuncia [text]. Detiene cualquier locucion en curso antes de empezar.
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await init();
    await _tts.stop();
    await _tts.speak(clean);
  }

  Future<void> stop() => _tts.stop();
}

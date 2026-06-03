/// Constantes globales de la aplicacion.
class AppConstants {
  const AppConstants._();

  /// URL base del servidor de reconocimiento (Flask + MediaPipe + SigLIP2).
  ///
  /// Cambia esta IP por la de la maquina que corre `flask_server.py`, dentro
  /// de la misma red local que el dispositivo.
  static const String serverUrl = 'http://144.22.43.169:5000';

  static const String healthPath = '/health';
  static const String recognizePath = '/recognize';

  /// Timeout de la peticion de reconocimiento.
  static const Duration requestTimeout = Duration(seconds: 18);

  /// Timeout de la comprobacion de salud del servidor.
  static const Duration healthTimeout = Duration(seconds: 4);

  /// Intervalo entre capturas en modo deteccion continua.
  static const Duration captureInterval = Duration(milliseconds: 1200);

  /// Capturas consecutivas con la misma letra para fijarla en la palabra.
  static const int wordStabilityCaptures = 2;

  /// Capturas de espera tras fijar una letra antes de poder fijar otra.
  static const int wordCooldownCaptures = 2;

  /// Idioma usado para la sintesis de voz (TTS).
  static const String ttsLanguage = 'es-ES';
}

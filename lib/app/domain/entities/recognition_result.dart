/// Entidad de dominio que representa el resultado de clasificar una sena.
///
/// Pertenece a la capa de dominio: es Dart puro, sin dependencias de Flutter
/// ni de paquetes externos, de modo que la logica de negocio queda aislada.
class RecognitionResult {
  const RecognitionResult({
    required this.letter,
    required this.confidence,
    required this.handDetected,
  });

  /// Letra reconocida (A-Z) o '--' cuando no hay una prediccion valida.
  final String letter;

  /// Confianza de la prediccion en el rango [0, 1].
  final double confidence;

  /// Indica si se considera que hay una mano clara en cuadro.
  final bool handDetected;

  /// Resultado vacio, usado como estado inicial o al limpiar.
  static const RecognitionResult empty = RecognitionResult(
    letter: '--',
    confidence: 0,
    handDetected: false,
  );

  RecognitionResult copyWith({
    String? letter,
    double? confidence,
    bool? handDetected,
  }) {
    return RecognitionResult(
      letter: letter ?? this.letter,
      confidence: confidence ?? this.confidence,
      handDetected: handDetected ?? this.handDetected,
    );
  }
}

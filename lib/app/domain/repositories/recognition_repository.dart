import 'dart:typed_data';

import '../entities/recognition_result.dart';

/// Contrato de la capa de dominio para reconocer senas.
///
/// La presentacion depende de esta abstraccion, no de una implementacion
/// concreta (inversion de dependencias). La capa de datos provee la
/// implementacion real (servidor REST con MediaPipe + SigLIP2).
abstract class RecognitionRepository {
  /// Inicializa el repositorio y comprueba que la fuente este disponible.
  Future<void> init();

  /// `true` cuando la fuente de reconocimiento esta lista y operativa.
  bool get isReady;

  /// Clasifica una imagen JPEG y devuelve la letra reconocida.
  Future<RecognitionResult> recognizeJpeg(Uint8List jpegBytes);

  /// Libera los recursos nativos del interprete.
  void dispose();
}

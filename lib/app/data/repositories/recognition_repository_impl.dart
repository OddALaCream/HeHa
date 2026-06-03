import 'dart:typed_data';

import '../../domain/entities/recognition_result.dart';
import '../../domain/repositories/recognition_repository.dart';
import '../datasources/asl_rest_datasource.dart';

/// Implementacion del repositorio basada en el servidor REST
/// (MediaPipe + SigLIP2). Traduce la respuesta del servidor a la entidad
/// de dominio [RecognitionResult].
class RecognitionRepositoryImpl implements RecognitionRepository {
  RecognitionRepositoryImpl(this._dataSource);

  final AslRestDataSource _dataSource;

  @override
  bool get isReady => _dataSource.isReady;

  @override
  Future<void> init() => _dataSource.checkHealth();

  @override
  Future<RecognitionResult> recognizeJpeg(Uint8List jpegBytes) async {
    final prediction = await _dataSource.recognizeJpeg(jpegBytes);
    return RecognitionResult(
      letter: prediction.letter,
      confidence: prediction.confidence,
      handDetected: prediction.handDetected,
    );
  }

  @override
  void dispose() => _dataSource.close();
}

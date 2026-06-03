import 'package:asl_recognition/app/domain/entities/recognition_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecognitionResult', () {
    test('empty tiene valores neutros', () {
      expect(RecognitionResult.empty.letter, '--');
      expect(RecognitionResult.empty.confidence, 0);
      expect(RecognitionResult.empty.handDetected, isFalse);
    });

    test('copyWith reemplaza solo los campos indicados', () {
      const base = RecognitionResult.empty;
      final updated = base.copyWith(letter: 'A', confidence: 0.9, handDetected: true);

      expect(updated.letter, 'A');
      expect(updated.confidence, 0.9);
      expect(updated.handDetected, isTrue);
      // El original no cambia (inmutabilidad).
      expect(base.letter, '--');
    });
  });
}

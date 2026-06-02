import 'package:asl_recognition/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the recognition shell', (tester) async {
    await tester.pumpWidget(
      const SignRecognitionApp(
        cameras: [],
        autoCheckServer: false,
      ),
    );

    expect(find.text('Verificacion ASL'), findsOneWidget);
    expect(find.text('Modelo: sign_language_recognition_v2'), findsOneWidget);
    expect(find.text('EN VIVO'), findsOneWidget);
  });
}

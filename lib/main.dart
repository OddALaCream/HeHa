import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SignRecognitionApp());
}

/// Raiz de la aplicacion. Es un [StatelessWidget] y usa [GetMaterialApp]
/// para gestion de estado, inyeccion de dependencias y rutas (GetX).
class SignRecognitionApp extends StatelessWidget {
  const SignRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sign Language Recognition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}

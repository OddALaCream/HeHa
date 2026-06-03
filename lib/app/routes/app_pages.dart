import 'package:get/get.dart';

import '../presentation/bindings/recognition_binding.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/pages/manual_page.dart';
import '../presentation/pages/recognition_page.dart';
import 'app_routes.dart';

/// Tabla de rutas de GetX. El [RecognitionBinding] se asocia a la ruta de la
/// camara, de modo que la camara y el servidor solo se inicializan al entrar
/// a reconocer (no en el menu de inicio).
class AppPages {
  AppPages._();

  static const String initial = Routes.home;

  static final List<GetPage> routes = <GetPage>[
    GetPage(
      name: Routes.home,
      page: () => const HomePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.recognition,
      page: () => const RecognitionPage(),
      binding: RecognitionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.manual,
      page: () => const ManualPage(),
      transition: Transition.rightToLeft,
    ),
  ];
}

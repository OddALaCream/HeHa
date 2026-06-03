import 'package:get/get.dart';

import '../../core/services/speech_service.dart';
import '../../data/datasources/asl_rest_datasource.dart';
import '../../data/repositories/recognition_repository_impl.dart';
import '../../domain/repositories/recognition_repository.dart';
import '../controllers/recognition_controller.dart';

/// Inyeccion de dependencias de la feature de reconocimiento.
///
/// Conecta las capas siguiendo la regla de dependencia de Clean Architecture:
/// la presentacion recibe la abstraccion [RecognitionRepository], cuya
/// implementacion concreta vive en la capa de datos y usa el datasource REST.
class RecognitionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AslRestDataSource>(() => AslRestDataSource());
    Get.lazyPut<SpeechService>(() => SpeechService());
    Get.lazyPut<RecognitionRepository>(
      () => RecognitionRepositoryImpl(Get.find<AslRestDataSource>()),
    );
    Get.lazyPut<RecognitionController>(
      () => RecognitionController(
        Get.find<RecognitionRepository>(),
        Get.find<SpeechService>(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/recognition_controller.dart';
import '../widgets/camera_pane.dart';
import '../widgets/control_panel.dart';

/// Pantalla principal de reconocimiento. Hereda de [StatelessWidget]
/// (via [GetView]); todo el estado vive en el [RecognitionController].
class RecognitionPage extends GetView<RecognitionController> {
  const RecognitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            if (wide) {
              // Pantalla ancha: camara a la izquierda, panel lateral con
              // su propio scroll a la derecha.
              return const Row(
                children: [
                  Expanded(child: CameraPane()),
                  SizedBox(width: 380, child: ControlPanel()),
                ],
              );
            }

            // Movil: zonas acotadas. La camara ocupa la parte superior y el
            // panel la inferior; el panel scrollea SOLO dentro de su zona
            // (nunca toda la pagina), evitando cualquier scroll infinito.
            return const Column(
              children: [
                Expanded(flex: 3, child: CameraPane()),
                Expanded(flex: 4, child: ControlPanel()),
              ],
            );
          },
        ),
      ),
    );
  }
}

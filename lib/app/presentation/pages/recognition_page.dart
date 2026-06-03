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
              return const Row(
                children: [
                  Expanded(child: CameraPane()),
                  SizedBox(width: 380, child: ControlPanel()),
                ],
              );
            }

            final panelHeight = constraints.maxHeight < 680
                ? constraints.maxHeight * 0.52
                : 360.0;

            return Column(
              children: [
                const Expanded(child: CameraPane()),
                SizedBox(height: panelHeight, child: const ControlPanel()),
              ],
            );
          },
        ),
      ),
    );
  }
}

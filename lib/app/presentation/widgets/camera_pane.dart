import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/recognition_controller.dart';
import 'focus_frame.dart';

/// Panel con el preview de la camara, el badge y el marco de enfoque.
class CameraPane extends StatelessWidget {
  const CameraPane({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GetBuilder<RecognitionController>(
            builder: (controller) {
              final camera = controller.cameraController;
              final ready = camera != null && camera.value.isInitialized;
              if (!ready) {
                return const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  ),
                );
              }
              // El preview cubre toda la seccion (recorta en vez de dejar
              // franjas negras). Se usa OverflowBox + AspectRatio en vez de
              // FittedBox/Transform porque la textura nativa de la camara se
              // renderiza en blanco dentro de esos widgets.
              return ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ar = camera.value.aspectRatio;
                    var w = constraints.maxWidth;
                    var h = w / ar;
                    if (h < constraints.maxHeight) {
                      h = constraints.maxHeight;
                      w = h * ar;
                    }
                    return OverflowBox(
                      minWidth: w,
                      maxWidth: w,
                      minHeight: h,
                      maxHeight: h,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: AspectRatio(
                          aspectRatio: ar,
                          child: CameraPreview(camera),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Positioned.fill(
            child: Obx(
              () => FocusFrame(
                active: Get.find<RecognitionController>().recognizing.value,
              ),
            ),
          ),
          // Indicador de carga mientras el servidor procesa la seña.
          Positioned.fill(
            child: Obx(
              () => _ProcessingOverlay(
                visible: Get.find<RecognitionController>().recognizing.value,
              ),
            ),
          ),
          const Positioned(left: 20, top: 18, child: _CameraBadge()),
          // Boton pequeno para detener / reanudar la deteccion.
          const Positioned(
            right: 16,
            bottom: 16,
            child: _DetectionToggle(),
          ),
        ],
      ),
    );
  }
}

/// Boton compacto que pausa o reanuda la deteccion de señas.
class _DetectionToggle extends StatelessWidget {
  const _DetectionToggle();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecognitionController>();
    // El Obx lee los observables DENTRO de su closure (uso correcto).
    return Obx(() {
      final live = controller.liveEnabled.value;
      final ready = controller.cameraReady.value;
      return Material(
        color: AppTheme.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: ready ? controller.toggleLive : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  live ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                  size: 16,
                  color: AppTheme.black,
                ),
                const SizedBox(width: 6),
                Text(
                  live ? 'DETENER' : 'REANUDAR',
                  style: const TextStyle(
                    color: AppTheme.black,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: visible ? 1 : 0,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Procesando seña...',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border.all(color: AppTheme.black),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'SIGN LANGUAGE RECOGNITION  ·  SIGLIP2',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

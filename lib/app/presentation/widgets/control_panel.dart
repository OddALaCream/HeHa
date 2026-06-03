import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/recognition_controller.dart';
import 'result_box.dart';
import 'status_box.dart';
import 'word_box.dart';

/// Panel lateral de control. Es un [StatelessWidget] que lee el estado
/// reactivo del [RecognitionController] mediante `Obx`.
class ControlPanel extends GetView<RecognitionController> {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(left: BorderSide(color: AppTheme.black, width: 1)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verificacion ASL',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Servidor: MediaPipe + SigLIP2',
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            const SizedBox(height: 20),
            Obx(() => ResultBox(result: controller.result.value)),
            const SizedBox(height: 16),
            Obx(
              () => WordBox(
                word: controller.word.value,
                recognizing: controller.recognizing.value,
                onSpace: controller.addSpace,
                onBackspace: controller.backspace,
                onClear: controller.clearWord,
                onSpeak: controller.speakWord,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => StatusBox(
                serverReady: controller.serverReady.value,
                checkingServer: controller.checkingServer.value,
                recognizing: controller.recognizing.value,
                status: controller.status.value,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => OutlinedButton.icon(
                      onPressed: controller.checkingServer.value
                          ? null
                          : controller.checkServer,
                      icon: controller.checkingServer.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.black,
                              ),
                            )
                          : const Icon(Icons.sync, size: 18),
                      label: const Text('VERIFICAR'),
                      style: _outlinedStyle(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Limpiar resultado',
                  onPressed: controller.clearResult,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.black,
                    side: const BorderSide(color: AppTheme.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() => _LiveButton(controller: controller)),
          ],
        ),
      ),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.black,
      side: const BorderSide(color: AppTheme.black),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _LiveButton extends StatelessWidget {
  const _LiveButton({required this.controller});

  final RecognitionController controller;

  @override
  Widget build(BuildContext context) {
    final live = controller.liveEnabled.value;
    final recognizing = controller.recognizing.value;
    final label = live ? (recognizing ? 'DETECTANDO' : 'EN VIVO') : 'REANUDAR';

    return FilledButton.icon(
      onPressed: controller.cameraReady.value ? controller.toggleLive : null,
      icon: recognizing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.white,
              ),
            )
          : Icon(
              live ? Icons.pause_circle_outline : Icons.play_circle_outline,
              size: 19,
            ),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.black,
        foregroundColor: AppTheme.white,
        disabledBackgroundColor: const Color(0xFFBDBDBD),
        disabledForegroundColor: AppTheme.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

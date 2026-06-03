import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/recognition_result.dart';

/// Tarjeta con la letra reconocida y la barra de confianza.
///
/// Usa animaciones implicitas controladas: la letra entra con una transicion
/// de escala + opacidad ([AnimatedSwitcher]) y la barra de confianza se llena
/// suavemente ([TweenAnimationBuilder]).
class ResultBox extends StatelessWidget {
  const ResultBox({super.key, required this.result});

  final RecognitionResult result;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.black, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESULTADO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.grey,
                letterSpacing: 0.9,
              ),
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.7, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  result.letter,
                  key: ValueKey<String>(result.letter),
                  style: const TextStyle(
                    fontSize: 78,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                tween: Tween<double>(begin: 0, end: result.confidence),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 9,
                    backgroundColor: AppTheme.lightGrey,
                    color: AppTheme.black,
                  );
                },
              ),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(result.confidence * 100).round()}% confianza',
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                ),
                Text(
                  result.handDetected ? 'SENA DETECTADA' : 'SIN SENA',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

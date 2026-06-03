import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tarjeta que muestra la palabra formada por las señas detectadas y permite
/// editarla y pronunciarla. Incluye un indicador de carga en la cabecera que
/// se enciende mientras el servidor procesa una seña.
class WordBox extends StatelessWidget {
  const WordBox({
    super.key,
    required this.word,
    required this.recognizing,
    required this.onSpace,
    required this.onBackspace,
    required this.onClear,
    required this.onSpeak,
  });

  final String word;
  final bool recognizing;
  final VoidCallback onSpace;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final hasWord = word.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.black, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'PALABRA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.grey,
                    letterSpacing: 0.9,
                  ),
                ),
                const Spacer(),
                // Indicador de carga durante la solicitud al servidor.
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: recognizing ? 1 : 0,
                  child: const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Texto formado, con cursor.
            SizedBox(
              width: double.infinity,
              child: Text(
                hasWord ? '${word}_' : '_',
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniButton(
                    icon: Icons.space_bar,
                    label: 'ESPACIO',
                    onPressed: onSpace,
                  ),
                ),
                const SizedBox(width: 8),
                _IconMiniButton(
                  icon: Icons.backspace_outlined,
                  tooltip: 'Borrar letra',
                  onPressed: onBackspace,
                ),
                const SizedBox(width: 8),
                _IconMiniButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Limpiar palabra',
                  onPressed: onClear,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Boton principal: pronunciar la frase.
            FilledButton.icon(
              onPressed: hasWord ? onSpeak : null,
              icon: const Icon(Icons.volume_up, size: 19),
              label: const Text('HABLAR'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.black,
                foregroundColor: AppTheme.white,
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                disabledForegroundColor: AppTheme.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.black,
        side: const BorderSide(color: AppTheme.black),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _IconMiniButton extends StatelessWidget {
  const _IconMiniButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      style: IconButton.styleFrom(
        foregroundColor: AppTheme.black,
        side: const BorderSide(color: AppTheme.black),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

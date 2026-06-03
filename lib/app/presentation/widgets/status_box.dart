import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tarjeta de estado de la conexion con el servidor de reconocimiento.
class StatusBox extends StatelessWidget {
  const StatusBox({
    super.key,
    required this.serverReady,
    required this.checkingServer,
    required this.recognizing,
    required this.status,
  });

  final bool serverReady;
  final bool checkingServer;
  final bool recognizing;
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = checkingServer
        ? 'COMPROBANDO'
        : serverReady
            ? 'SERVIDOR EN LINEA'
            : 'SERVIDOR OFFLINE';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelGrey,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Punto de actividad que se atenua al inferir.
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: recognizing ? 0.3 : 1.0,
                  child: Icon(
                    serverReady
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 17,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.black,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                status,
                key: ValueKey<String>(status),
                style: const TextStyle(
                  color: AppTheme.black,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

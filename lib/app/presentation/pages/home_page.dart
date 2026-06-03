import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

/// Menu de inicio de la aplicacion. Mantiene la paleta monocroma (blanco y
/// negro) del resto de la app. Hereda de [StatelessWidget].
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const double _verticalPadding = 32;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: _verticalPadding,
              ),
              // Centra el contenido; solo hace scroll si no cabe en pantalla.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - _verticalPadding * 2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _AnimatedContent(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          const SizedBox(height: 40),
          _MenuButton(
            icon: Icons.videocam_outlined,
            title: 'RECONOCER SEÑAS',
            subtitle: 'Camara + voz en tiempo real',
            filled: true,
            onTap: () => Get.toNamed(Routes.recognition),
          ),
          const SizedBox(height: 14),
          _MenuButton(
            icon: Icons.menu_book_outlined,
            title: 'MANUAL DE USUARIO',
            subtitle: 'Como usar la aplicacion',
            filled: false,
            onTap: () => Get.toNamed(Routes.manual),
          ),
          const SizedBox(height: 36),
          const Text(
            'IA: MediaPipe + SigLIP2',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.grey),
          ),
        ],
      ),
    );
  }
}

/// Cabecera de marca: bloque negro con el nombre, estilo del badge de la app.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppTheme.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.sign_language, color: AppTheme.white, size: 50),
        ),
        const SizedBox(height: 22),
        const Text(
          'Sign Language\nRecognition',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: AppTheme.black,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Reconocimiento del alfabeto ASL (A-Z)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.grey),
        ),
      ],
    );
  }
}

/// Boton de menu con icono, titulo y subtitulo. Variante rellena o con borde.
class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppTheme.white : AppTheme.black;
    final bg = filled ? AppTheme.black : AppTheme.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.black, width: 1.4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: fg,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: filled ? const Color(0xFFBDBDBD) : AppTheme.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: fg, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

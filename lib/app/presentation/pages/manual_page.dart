import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Manual de usuario. Explica el flujo de uso de la app. [StatelessWidget].
class ManualPage extends StatelessWidget {
  const ManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
        surfaceTintColor: AppTheme.white,
        title: const Text(
          'Manual de usuario',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.black),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        children: const [
          _Intro(),
          SizedBox(height: 22),
          _Step(
            number: '1',
            icon: Icons.dns_outlined,
            title: 'Enciende el servidor',
            body:
                'La app envia la imagen a un servidor que detecta la mano y '
                'reconoce la letra. Asegurate de que el servidor este corriendo '
                'y que el telefono este en la misma red. Pulsa VERIFICAR para '
                'reintentar la conexion.',
          ),
          _Step(
            number: '2',
            icon: Icons.front_hand_outlined,
            title: 'Haz la sena',
            body:
                'Coloca la mano dentro del recuadro de enfoque y manten la sena '
                'quieta un momento. Mientras se procesa veras un indicador de '
                'carga; luego aparece la letra y su porcentaje de confianza.',
          ),
          _Step(
            number: '3',
            icon: Icons.text_fields,
            title: 'Forma palabras',
            body:
                'Cada letra estable se va agregando a la PALABRA. Usa ESPACIO '
                'para separar palabras, el boton de retroceso para borrar la '
                'ultima letra y la papelera para limpiar todo.',
          ),
          _Step(
            number: '4',
            icon: Icons.volume_up_outlined,
            title: 'Escucha la voz',
            body:
                'Pulsa HABLAR para que la app pronuncie la frase formada. '
                'Ademas, al pulsar ESPACIO se pronuncia automaticamente la '
                'palabra recien terminada.',
          ),
          _Step(
            number: '5',
            icon: Icons.pause_circle_outline,
            title: 'Pausa y reanuda',
            body:
                'EN VIVO detecta de forma continua. Puedes pausar la deteccion '
                'con el mismo boton (REANUDAR) sin apagar la camara.',
          ),
          SizedBox(height: 18),
          _Note(),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Esta app reconoce el alfabeto del lenguaje de senas americano '
          '(A-Z), forma palabras con las letras detectadas y las pronuncia '
          'en voz alta.',
          style: TextStyle(color: AppTheme.white, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.black, width: 1.4),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppTheme.black,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppTheme.black),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF404040),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelGrey,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: AppTheme.black),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Consejo: las letras J y Z implican movimiento, por lo que '
                'pueden ser mas dificiles de reconocer con una sola captura.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: AppTheme.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

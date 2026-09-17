import 'package:flutter/material.dart';

class FestivalMapScreen extends StatelessWidget {
  const FestivalMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _FestivalMapPainter(Theme.of(context).colorScheme),
                child: const Center(child: Text('Mapa offline del festival')),
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.offline_bolt),
              title: Text('Modo offline-first activo'),
              subtitle: Text('Se conserva la última ubicación conocida del squad.'),
            ),
            const ListTile(
              leading: Icon(Icons.battery_saver),
              title: Text('GPS optimizado'),
              subtitle: Text('Sincroniza con movimiento mayor a 15 m o cada 3 min en segundo plano.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FestivalMapPainter extends CustomPainter {
  const _FestivalMapPainter(this.colorScheme);

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.24)
      ..lineTo(size.width * 0.82, size.height * 0.18)
      ..lineTo(size.width * 0.90, size.height * 0.72)
      ..lineTo(size.width * 0.32, size.height * 0.86)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

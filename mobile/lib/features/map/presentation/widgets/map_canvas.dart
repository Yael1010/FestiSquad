import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/festival_map.dart';

class FestivalMapCanvas extends StatelessWidget {
  const FestivalMapCanvas({
    super.key,
    required this.snapshot,
    this.myLocation,
  });

  final FestivalMapSnapshot snapshot;
  final MapPoint? myLocation;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: CustomPaint(
          painter: _FestivalPainter(snapshot, myLocation),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _FestivalPainter extends CustomPainter {
  _FestivalPainter(this.snapshot, this.myLocation);

  final FestivalMapSnapshot snapshot;
  final MapPoint? myLocation;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF081423),
    );
    if (snapshot.festival.boundary.isEmpty) return;

    final points = snapshot.festival.boundary;
    final minLat = points.map((p) => p.latitude).reduce(math.min);
    final maxLat = points.map((p) => p.latitude).reduce(math.max);
    final minLon = points.map((p) => p.longitude).reduce(math.min);
    final maxLon = points.map((p) => p.longitude).reduce(math.max);
    final latSpan = math.max(maxLat - minLat, 0.00001);
    final lonSpan = math.max(maxLon - minLon, 0.00001);
    final scale = math.min(
      size.width * .80 / lonSpan,
      size.height * .65 / latSpan,
    );
    final centerX = (minLon + maxLon) / 2;
    final centerY = (minLat + maxLat) / 2;

    Offset project(MapPoint point) => Offset(
          size.width / 2 + (point.longitude - centerX) * scale,
          size.height / 2 - (point.latitude - centerY) * scale,
        );

    Path shape(List<MapPoint> vertices) {
      final path = Path();
      if (vertices.isEmpty) return path;
      path.moveTo(project(vertices.first).dx, project(vertices.first).dy);
      for (final point in vertices.skip(1)) {
        final offset = project(point);
        path.lineTo(offset.dx, offset.dy);
      }
      return path..close();
    }

    final boundary = shape(points);
    canvas.drawPath(boundary, Paint()..color = const Color(0xFF103047));
    canvas.drawPath(
      boundary,
      Paint()
        ..color = const Color(0xFF35C4CF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (final stage in snapshot.festival.stages) {
      canvas.drawPath(
          shape(stage.polygon), Paint()..color = const Color(0xFF286C80));
      _label(
        canvas,
        project(_center(stage.polygon)),
        stage.name,
        const Color(0xFFFFFFFF),
      );
    }
    for (final point in snapshot.meetingPoints) {
      final offset = project(MapPoint(point.latitude, point.longitude));
      _marker(canvas, offset, const Color(0xFFFFC857));
      _label(canvas, offset + const Offset(0, -22), point.title,
          const Color(0xFFFFC857));
    }
    for (final location in snapshot.locations) {
      _marker(
        canvas,
        project(MapPoint(location.latitude, location.longitude)),
        const Color(0xFF72E1A6),
      );
    }
    if (myLocation != null) {
      final offset = project(myLocation!);
      canvas.drawCircle(offset, 14, Paint()..color = const Color(0x6635C4CF));
      _marker(canvas, offset, const Color(0xFF35C4CF));
    }
  }

  MapPoint _center(List<MapPoint> points) {
    if (points.isEmpty) return const MapPoint(0, 0);
    return MapPoint(
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
    );
  }

  void _marker(Canvas canvas, Offset point, Color color) {
    canvas.drawCircle(point, 8, Paint()..color = color);
    canvas.drawCircle(
      point,
      8,
      Paint()
        ..color = const Color(0xFF081423)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _label(Canvas canvas, Offset center, String label, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 130);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FestivalPainter oldDelegate) =>
      oldDelegate.snapshot != snapshot || oldDelegate.myLocation != myLocation;
}

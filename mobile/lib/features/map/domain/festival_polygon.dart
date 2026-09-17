class FestivalPolygon {
  const FestivalPolygon({
    required this.id,
    required this.name,
    required this.points,
  });

  final String id;
  final String name;
  final List<GeoPoint> points;
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}


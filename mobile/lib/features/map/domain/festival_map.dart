import 'dart:convert';

class MapPoint {
  const MapPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  factory MapPoint.fromJson(dynamic value) {
    final pair = value as List;
    return MapPoint(
      (pair[0] as num).toDouble(),
      (pair[1] as num).toDouble(),
    );
  }

  factory MapPoint.fromGeoJson(dynamic value) {
    final pair = value as List;
    return MapPoint(
      (pair[1] as num).toDouble(),
      (pair[0] as num).toDouble(),
    );
  }
}

List<MapPoint> parsePolygon(dynamic value) {
  final raw = value is String ? jsonDecode(value) : value;
  if (raw is Map) {
    final coordinates = raw['coordinates'][0] as List;
    return coordinates.map(MapPoint.fromGeoJson).toList(growable: false);
  }
  return (raw as List).map(MapPoint.fromJson).toList(growable: false);
}

class FestivalStage {
  const FestivalStage({
    required this.id,
    required this.name,
    required this.polygon,
  });

  final String id;
  final String name;
  final List<MapPoint> polygon;
}

class FestivalMap {
  const FestivalMap({
    required this.id,
    required this.name,
    required this.boundary,
    required this.stages,
    required this.isDemo,
  });

  final String id;
  final String name;
  final List<MapPoint> boundary;
  final List<FestivalStage> stages;
  final bool isDemo;

  factory FestivalMap.fromJson(Map<String, dynamic> json,
      {bool isDemo = false}) {
    return FestivalMap(
      id: json['id'] as String,
      name: json['name'] as String,
      boundary: parsePolygon(json['boundary']),
      stages: (json['stages'] as List)
          .map((item) => FestivalStage(
                id: item['id'] as String,
                name: item['name'] as String,
                polygon: parsePolygon(item['polygon']),
              ))
          .toList(growable: false),
      isDemo: isDemo,
    );
  }
}

class MemberLocation {
  const MemberLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final String userId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
}

class MapMeetingPoint {
  const MapMeetingPoint({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String title;
  final double latitude;
  final double longitude;
}

class FestivalMapSnapshot {
  const FestivalMapSnapshot({
    required this.festival,
    required this.locations,
    required this.meetingPoints,
    required this.fromCache,
  });

  final FestivalMap festival;
  final List<MemberLocation> locations;
  final List<MapMeetingPoint> meetingPoints;
  final bool fromCache;
}

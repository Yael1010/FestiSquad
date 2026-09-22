import 'dart:math';

class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
}

class LocationSyncPolicy {
  const LocationSyncPolicy({
    this.minimumDistanceMeters = 15,
    this.backgroundInterval = const Duration(minutes: 3),
  });

  final double minimumDistanceMeters;
  final Duration backgroundInterval;

  bool shouldSync({
    required LocationSnapshot? lastSynced,
    required LocationSnapshot current,
    required bool isInBackground,
  }) {
    if (lastSynced == null) {
      return true;
    }

    if (isInBackground &&
        current.recordedAt.difference(lastSynced.recordedAt) <
            backgroundInterval) {
      return false;
    }

    final distance = _haversineMeters(lastSynced, current);
    if (distance >= minimumDistanceMeters) {
      return true;
    }

    if (isInBackground &&
        current.recordedAt.difference(lastSynced.recordedAt) >=
            backgroundInterval) {
      return true;
    }

    return false;
  }

  double _haversineMeters(LocationSnapshot a, LocationSnapshot b) {
    const earthRadiusMeters = 6371000;
    final dLat = _degreesToRadians(b.latitude - a.latitude);
    final dLon = _degreesToRadians(b.longitude - a.longitude);
    final lat1 = _degreesToRadians(a.latitude);
    final lat2 = _degreesToRadians(b.latitude);

    final value = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadiusMeters * 2 * atan2(sqrt(value), sqrt(1 - value));
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;
}

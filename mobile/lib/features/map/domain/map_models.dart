enum NetworkStatus { online, offline, checking, unknown }

class Totem {
  const Totem({
    required this.id,
    required this.name,
    required this.location,
    required this.distanceMeters,
  });

  final String id;
  final String name;
  final String location;
  final int distanceMeters;
}

class NearbyPerson {
  const NearbyPerson({
    required this.id,
    required this.name,
    required this.distanceMeters,
  });

  final String id;
  final String name;
  final int distanceMeters;
}

abstract interface class MapRepository {
  List<Totem> get totems;

  Future<List<NearbyPerson>> nearbyPeople(String totemId);

  Stream<NetworkStatus> watchNetwork();
}

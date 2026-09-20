import '../domain/map_models.dart';

/// Provides deterministic sample data until the remote and local data sources
/// are connected to the repository contract.
class DemoMapRepository implements MapRepository {
  @override
  List<Totem> get totems => const [
        Totem(
          id: 'north',
          name: 'Totem Norte',
          location: 'Junto al escenario principal',
          distanceMeters: 120,
        ),
        Totem(
          id: 'south',
          name: 'Totem Sur',
          location: 'Entrada sur',
          distanceMeters: 340,
        ),
      ];

  @override
  Future<List<NearbyPerson>> nearbyPeople(String totemId) async {
    if (totemId != 'north') return const [];

    return const [
      NearbyPerson(id: '1', name: 'Ana', distanceMeters: 25),
      NearbyPerson(id: '2', name: 'Luis', distanceMeters: 60),
      NearbyPerson(id: '3', name: 'Dani', distanceMeters: 85),
    ];
  }

  @override
  Stream<NetworkStatus> watchNetwork() => Stream.value(NetworkStatus.unknown);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_map_repository.dart';
import '../domain/map_models.dart';

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => DemoMapRepository(),
);

final totemsProvider = Provider<List<Totem>>(
  (ref) => ref.watch(mapRepositoryProvider).totems,
);

final selectedTotemIdProvider = NotifierProvider<SelectedTotemId, String?>(
  SelectedTotemId.new,
);

class SelectedTotemId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;

  void clear() => state = null;
}

final selectedTotemProvider = Provider<Totem?>((ref) {
  final selectedId = ref.watch(selectedTotemIdProvider);

  for (final totem in ref.watch(totemsProvider)) {
    if (totem.id == selectedId) return totem;
  }

  return null;
});

final networkStatusProvider = StreamProvider<NetworkStatus>(
  (ref) => ref.watch(mapRepositoryProvider).watchNetwork(),
);

final nearbyPeopleProvider = FutureProvider.autoDispose
    .family<List<NearbyPerson>, String>((ref, totemId) {
  return ref.watch(mapRepositoryProvider).nearbyPeople(totemId);
});

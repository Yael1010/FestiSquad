import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_state.dart';
import '../data/festival_repository.dart';
import '../domain/festival.dart';

final festivalCatalogControllerProvider = StateNotifierProvider.autoDispose<
    FestivalCatalogController,
    AsyncValue<OfflineData<List<FestivalSummary>>>>((ref) {
  return FestivalCatalogController(ref.watch(festivalRepositoryProvider));
});

final festivalAdminAccessProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(festivalRepositoryProvider).hasAdminAccess();
});

class FestivalCatalogController
    extends StateNotifier<AsyncValue<OfflineData<List<FestivalSummary>>>> {
  FestivalCatalogController(this._repository)
      : super(const AsyncValue.loading()) {
    load();
  }

  final FestivalRepository _repository;

  Future<void> load({bool forceRefresh = false}) async {
    try {
      state = AsyncValue.data(
        await _repository.loadCatalog(forceRefresh: forceRefresh),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(apiErrorMessage(error), stackTrace);
    }
  }
}

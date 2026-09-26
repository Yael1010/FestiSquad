import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/clash_repository.dart';
import '../domain/clash_models.dart';

final clashControllerProvider =
    StateNotifierProvider<ClashController, AsyncValue<ClashSnapshot?>>((ref) {
  return ClashController(ref.watch(clashRepositoryProvider));
});

class ClashController extends StateNotifier<AsyncValue<ClashSnapshot?>> {
  ClashController(this._repository) : super(const AsyncValue.data(null));

  final ClashRepository _repository;

  Future<void> load(String squadId) => _run(() => _repository.load(squadId));

  Future<void> saveManual(
    String squadId,
    List<String> genres,
    List<String> artists,
  ) {
    return _run(() => _repository.saveManual(squadId, genres, artists));
  }

  Future<void> recommend(String squadId, ClashConflict conflict) {
    return _run(() => _repository.recommend(squadId, conflict));
  }

  Future<String> spotifyAuthorizationUrl() =>
      _repository.spotifyAuthorizationUrl();

  Future<void> _run(Future<ClashSnapshot> Function() request) async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await request());
    } catch (error, stackTrace) {
      state = AsyncValue.error(apiErrorMessage(error), stackTrace);
      if (previous != null) {
        state = AsyncValue.data(previous);
      }
      rethrow;
    }
  }
}

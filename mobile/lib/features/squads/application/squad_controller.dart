import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/squad_repository.dart';
import '../domain/squad.dart';

final squadControllerProvider =
    StateNotifierProvider<SquadController, AsyncValue<Squad?>>((ref) {
  return SquadController(ref.watch(squadRepositoryProvider));
});

class SquadController extends StateNotifier<AsyncValue<Squad?>> {
  SquadController(this._repository) : super(const AsyncValue.data(null));

  final SquadRepository _repository;
  bool _lastLoadWasFromCache = false;

  bool get lastLoadWasFromCache => _lastLoadWasFromCache;

  Future<Squad?> loadMine() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.loadMine();
      _lastLoadWasFromCache = result.fromCache;
      final squad = result.value.isEmpty ? null : result.value.first;
      state = AsyncValue.data(squad);
      return squad;
    } catch (error, stackTrace) {
      final message = apiErrorMessage(error);
      state = AsyncValue.error(message, stackTrace);
      throw SquadRequestException(message);
    }
  }

  Future<Squad> create(String name) => _run(() => _repository.create(name));

  Future<Squad> join(String code) => _run(() => _repository.join(code));

  Future<Squad> _run(Future<Squad> Function() request) async {
    state = const AsyncValue.loading();
    try {
      final squad = await request();
      state = AsyncValue.data(squad);
      return squad;
    } catch (error, stackTrace) {
      final message = apiErrorMessage(error);
      state = AsyncValue.error(message, stackTrace);
      throw SquadRequestException(message);
    }
  }
}

class SquadRequestException implements Exception {
  const SquadRequestException(this.message);

  final String message;
}

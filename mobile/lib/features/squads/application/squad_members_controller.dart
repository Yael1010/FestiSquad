import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_state.dart';
import '../data/squad_repository.dart';
import '../domain/squad.dart';
import 'squad_controller.dart';

final squadMembersControllerProvider = StateNotifierProvider.autoDispose.family<
    SquadMembersController,
    AsyncValue<OfflineData<List<SquadMemberProfile>>>,
    String>((ref, squadId) {
  return SquadMembersController(ref.watch(squadRepositoryProvider), squadId);
});

class SquadMembersController
    extends StateNotifier<AsyncValue<OfflineData<List<SquadMemberProfile>>>> {
  SquadMembersController(this._repository, this.squadId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final SquadRepository _repository;
  final String squadId;

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _repository.loadMembers(squadId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(apiErrorMessage(error), stackTrace);
    }
  }

  Future<void> updateRole(String userId, String role) {
    return _mutate(() => _repository.updateRole(squadId, userId, role));
  }

  Future<void> removeMember(String userId) {
    return _mutate(() => _repository.removeMember(squadId, userId));
  }

  Future<void> transferOwnership(String userId) {
    return _mutate(() => _repository.transferOwnership(squadId, userId));
  }

  Future<void> deleteSquad() {
    return _mutate(() => _repository.deleteSquad(squadId), reload: false);
  }

  Future<void> _mutate(
    Future<void> Function() operation, {
    bool reload = true,
  }) async {
    try {
      await operation();
      if (reload) await load();
    } catch (error) {
      throw SquadRequestException(apiErrorMessage(error));
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/finance_repository.dart';
import '../domain/finance_models.dart';

final financeControllerProvider =
    StateNotifierProvider<FinanceController, AsyncValue<FinanceSnapshot?>>(
        (ref) {
  return FinanceController(ref.watch(financeRepositoryProvider));
});

class FinanceController extends StateNotifier<AsyncValue<FinanceSnapshot?>> {
  FinanceController(this._repository) : super(const AsyncValue.data(null));

  final FinanceRepository _repository;

  Future<void> load(String squadId) async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.load(squadId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(apiErrorMessage(error), stackTrace);
    }
  }

  Future<void> create(ExpenseDraft draft) async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.create(draft));
    } catch (error, stackTrace) {
      final message = apiErrorMessage(error);
      state = AsyncValue.error(message, stackTrace);
      throw FinanceRequestException(message);
    }
  }
}

class FinanceRequestException implements Exception {
  const FinanceRequestException(this.message);

  final String message;
}

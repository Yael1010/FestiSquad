import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._repository) : super(const AsyncValue.loading()) {
    _restore();
  }

  final AuthRepository _repository;

  Future<void> _restore() async {
    try {
      state = AsyncValue.data(await _repository.restore());
    } catch (error, stackTrace) {
      state = AsyncValue.error(apiErrorMessage(error), stackTrace);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _authenticate(
      () => _repository.register(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _authenticate(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> _authenticate(Future<AuthSession> Function() request) async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await request());
    } catch (error, stackTrace) {
      final message = apiErrorMessage(error);
      state = AsyncValue.error(message, stackTrace);
      throw AuthRequestException(message);
    }
  }
}

class AuthRequestException implements Exception {
  const AuthRequestException(this.message);

  final String message;
}

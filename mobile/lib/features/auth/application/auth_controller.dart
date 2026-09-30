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
    _initialization = _restore();
  }

  final AuthRepository _repository;
  late final Future<void> _initialization;

  Future<void> get initialized => _initialization;

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
    await _initialization;
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
    await _initialization;
    await _authenticate(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<SocialAuthAttempt> startSocial(
    String provider, {
    bool link = false,
  }) async {
    try {
      return await _repository.startSocial(provider, link: link);
    } catch (error) {
      throw AuthRequestException(apiErrorMessage(error));
    }
  }

  Future<SocialAuthResult> finishSocial(String flowToken) async {
    await _initialization;
    try {
      final result = await _repository.finishSocial(flowToken);
      if (result.session != null) state = AsyncValue.data(result.session);
      return result;
    } catch (error) {
      throw AuthRequestException(apiErrorMessage(error));
    }
  }

  Future<void> logout() async {
    await _initialization;
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

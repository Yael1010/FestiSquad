import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/token_storage.dart';
import '../domain/auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

abstract interface class AuthRepository {
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession?> restore();

  Future<void> logout();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return _save(response.data);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _save(response.data);
  }

  @override
  Future<AuthSession?> restore() async {
    final stored = await _storage.readSession();
    if (stored == null) return null;
    return AuthSession(
      userId: stored.userId,
      accessToken: stored.accessToken,
      refreshToken: stored.refreshToken,
    );
  }

  @override
  Future<void> logout() => _storage.clear();

  Future<AuthSession> _save(dynamic data) async {
    final session = AuthSession.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
    await _storage.writeSession(
      StoredSession(
        userId: session.userId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      ),
    );
    return session;
  }
}

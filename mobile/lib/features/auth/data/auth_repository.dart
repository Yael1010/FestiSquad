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

  Future<SocialAuthAttempt> startSocial(
    String provider, {
    bool link = false,
  });

  Future<SocialAuthResult> finishSocial(String flowToken);

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
  Future<SocialAuthAttempt> startSocial(
    String provider, {
    bool link = false,
  }) async {
    final action = link ? 'link' : 'start';
    final response = await _api.post('/auth/social/$provider/$action');
    return SocialAuthAttempt.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<SocialAuthResult> finishSocial(String flowToken) async {
    final response = await _api.post(
      '/auth/social/session',
      data: {'flow_token': flowToken},
    );
    final result = SocialAuthResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    if (result.session != null) await _persist(result.session!);
    return result;
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
    await _persist(session);
    return session;
  }

  Future<void> _persist(AuthSession session) => _storage.writeSession(
        StoredSession(
          userId: session.userId,
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        ),
      );
}

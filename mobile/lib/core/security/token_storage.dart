import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(const FlutterSecureStorage()),
);

class StoredSession {
  const StoredSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
}

class TokenStorage {
  TokenStorage(this._storage);

  static const _userIdKey = 'auth_user_id';
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<StoredSession?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _userIdKey),
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
    ]);
    if (values.any((value) => value == null || value.isEmpty)) return null;

    return StoredSession(
      userId: values[0]!,
      accessToken: values[1]!,
      refreshToken: values[2]!,
    );
  }

  Future<void> writeSession(StoredSession session) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: session.userId),
      _storage.write(key: _accessTokenKey, value: session.accessToken),
      _storage.write(key: _refreshTokenKey, value: session.refreshToken),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}

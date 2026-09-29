import 'dart:async';

import 'package:festisquad/features/auth/application/auth_controller.dart';
import 'package:festisquad/features/auth/data/auth_repository.dart';
import 'package:festisquad/features/auth/domain/auth_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first login waits for session restoration and keeps the new session',
      () async {
    final repository = _DelayedRestoreAuthRepository();
    final controller = AuthController(repository);
    addTearDown(controller.dispose);

    final login = controller.login(
      email: 'yael@example.com',
      password: 'password123',
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.loginCalls, 0);
    repository.restored.complete(null);
    await login;

    expect(repository.loginCalls, 1);
    expect(controller.state.valueOrNull?.userId, _session.userId);
    expect(controller.state.hasError, isFalse);
  });

  test('failed restoration does not prevent an explicit login', () async {
    final repository = _DelayedRestoreAuthRepository();
    final controller = AuthController(repository);
    addTearDown(controller.dispose);

    repository.restored.completeError(StateError('cache unavailable'));
    await Future<void>.delayed(Duration.zero);

    await controller.login(
      email: 'yael@example.com',
      password: 'password123',
    );

    expect(repository.loginCalls, 1);
    expect(controller.state.valueOrNull, _session);
  });
}

const _session = AuthSession(
  userId: '00000000-0000-0000-0000-000000000001',
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
);

class _DelayedRestoreAuthRepository implements AuthRepository {
  final restored = Completer<AuthSession?>();
  int loginCalls = 0;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return _session;
  }

  @override
  Future<AuthSession?> restore() => restored.future;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async =>
      _session;

  @override
  Future<SocialAuthAttempt> startSocial(
    String provider, {
    bool link = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SocialAuthResult> finishSocial(String flowToken) {
    throw UnimplementedError();
  }
}

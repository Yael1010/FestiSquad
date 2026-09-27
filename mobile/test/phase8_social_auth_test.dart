import 'package:festisquad/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta el inicio OAuth sin recibir tokens de sesión', () {
    final attempt = SocialAuthAttempt.fromJson({
      'provider': 'google',
      'authorization_url': 'https://accounts.google.com/o/oauth2/v2/auth',
      'flow_token': 'secret-flow-token',
      'expires_in_seconds': 600,
    });

    expect(attempt.provider, 'google');
    expect(attempt.authorizationUrl, startsWith('https://'));
    expect(attempt.flowToken, 'secret-flow-token');
  });

  test('interpreta una sesión social completada', () {
    final result = SocialAuthResult.fromJson({
      'status': 'completed',
      'session': {
        'user_id': 'user-id',
        'access_token': 'access-token',
        'refresh_token': 'refresh-token',
      },
    });

    expect(result.status, SocialAuthStatus.completed);
    expect(result.session?.userId, 'user-id');
  });

  test('un flujo pendiente no inventa una sesión', () {
    final result = SocialAuthResult.fromJson({
      'status': 'pending',
      'session': null,
      'error': null,
    });

    expect(result.status, SocialAuthStatus.pending);
    expect(result.session, isNull);
  });
}

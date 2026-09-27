class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['user_id'] as String,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}

class SocialAuthAttempt {
  const SocialAuthAttempt({
    required this.provider,
    required this.authorizationUrl,
    required this.flowToken,
  });

  final String provider;
  final String authorizationUrl;
  final String flowToken;

  factory SocialAuthAttempt.fromJson(Map<String, dynamic> json) {
    return SocialAuthAttempt(
      provider: json['provider'] as String,
      authorizationUrl: json['authorization_url'] as String,
      flowToken: json['flow_token'] as String,
    );
  }
}

enum SocialAuthStatus { pending, completed, failed }

class SocialAuthResult {
  const SocialAuthResult({required this.status, this.session, this.error});

  final SocialAuthStatus status;
  final AuthSession? session;
  final String? error;

  factory SocialAuthResult.fromJson(Map<String, dynamic> json) {
    final status = SocialAuthStatus.values.byName(json['status'] as String);
    final sessionData = json['session'];
    return SocialAuthResult(
      status: status,
      session: sessionData is Map
          ? AuthSession.fromJson(Map<String, dynamic>.from(sessionData))
          : null,
      error: json['error'] as String?,
    );
  }
}

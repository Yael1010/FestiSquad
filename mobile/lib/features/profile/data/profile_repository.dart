import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ApiProfileRepository(ref.watch(apiClientProvider));
});

abstract interface class ProfileRepository {
  Future<UserProfile> getMe();

  Future<UserProfile> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  });

  Future<UserProfile> removeAvatar();
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<UserProfile> getMe() async {
    final response = await _api.get('/auth/me');
    return _profile(response.data);
  }

  @override
  Future<UserProfile> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await _api.post(
      '/auth/avatar',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    return _profile(response.data);
  }

  @override
  Future<UserProfile> removeAvatar() async {
    final response = await _api.delete('/auth/avatar');
    return _profile(response.data);
  }

  UserProfile _profile(dynamic data) {
    final payload = Map<String, dynamic>.from(data as Map);
    final avatarUrl = payload['avatar_url'];
    if (avatarUrl is String && avatarUrl.isNotEmpty) {
      payload['avatar_url'] = _api.resolveUrl(avatarUrl);
    }
    return UserProfile.fromJson(payload);
  }
}

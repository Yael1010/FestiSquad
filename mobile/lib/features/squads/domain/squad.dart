class Squad {
  const Squad({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.memberIds,
    required this.currentUserRole,
  });

  final String id;
  final String name;
  final String code;
  final String ownerId;
  final List<String> memberIds;
  final String currentUserRole;

  factory Squad.fromJson(Map<String, dynamic> json) {
    return Squad(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      ownerId: json['owner_id'] as String,
      memberIds: List<String>.from(json['member_ids'] as List),
      currentUserRole: json['current_user_role'] as String,
    );
  }
}

class SquadMemberProfile {
  const SquadMemberProfile({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
    required this.isOwner,
    required this.isCurrentUser,
    this.avatarUrl,
    this.lastLocationAt,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;
  final DateTime? lastLocationAt;
  final bool isOwner;
  final bool isCurrentUser;

  factory SquadMemberProfile.fromJson(Map<String, dynamic> json) {
    return SquadMemberProfile(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String).toLocal(),
      lastLocationAt: json['last_location_at'] == null
          ? null
          : DateTime.parse(json['last_location_at'] as String).toLocal(),
      isOwner: json['is_owner'] as bool,
      isCurrentUser: json['is_current_user'] as bool,
    );
  }

  bool get isAdmin => role == 'admin';
}

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

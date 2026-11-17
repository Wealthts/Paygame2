class AdminUserModel {
  final int userId;
  final String username;
  final String email;
  final String displayName;
  final String role;
  final bool isActive;
  final String createdAt;

  const AdminUserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      userId: int.parse(json['user_id'].toString()),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isActive: int.parse((json['is_active'] ?? 0).toString()) == 1,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

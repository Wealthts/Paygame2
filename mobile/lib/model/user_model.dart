class UserModel {
  final int userId;
  final String username;
  final String? email;
  final String? displayName;
  final String role;

  UserModel({
    required this.userId,
    required this.username,
    this.email,
    this.displayName,
    required this.role,
  });

  // Convert JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['user_id'];

    final int? id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');

    if (id == null) {
      throw const FormatException('Invalid user_id');
    }

    return UserModel(
      userId: id,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      displayName: json['display_name']?.toString(),
      role: json['role']?.toString() ?? 'user',
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'display_name': displayName,
      'role': role,
    };
  }

  // Check Admin
  bool get isAdmin => role == 'admin';
}

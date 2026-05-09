class User {
  final int id;
  final String username;
  final String? email;
  final String fullname;
  final String role;
  final String? image;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.fullname,
    required String role,
    this.image,
  }) : role = _normalizeRole(role);

  static String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    return normalized.isEmpty ? 'user' : normalized;
  }

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final int id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return User(
      id: id,
      username: (json['username'] ?? '').toString(),
      email: json['email']?.toString(),
      fullname: (json['fullname'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      image: json['image']?.toString(), // may be null - allowed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullname': fullname,
      'role': role,
      'image': image,
    };
  }
}
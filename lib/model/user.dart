class User {
  final String name_kh;
  final String name_en;
  final String student_id;
  final String pwd;
  final String role;

  User({
    required this.name_kh,
    required this.name_en,
    required this.student_id,
    required this.pwd,
    String role = 'user',
  }) : role = _normalizeRole(role);

  static String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    return normalized.isEmpty ? 'user' : normalized;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name_kh: json['name_kh'] ?? '',
      name_en: json['name_en'] ?? '',
      student_id: json['student_id'] ?? '',
      pwd: json['pwd'] ?? '',
      role: (json['role'] ?? 'user').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_kh': name_kh,
      'name_en': name_en,
      'student_id': student_id,
      'pwd': pwd,
      'role': role,
    };
  }
}

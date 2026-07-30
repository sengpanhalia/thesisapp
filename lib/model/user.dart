// class User {
//   final String student_id;
//   final String username;
//   // final String? email;
//   final String fullname;
//   final String role;
//   final String? image;

//   User({
//     required this.student_id,
//     required this.username,
//     // this.email,
//     required this.fullname,
//     required String role,
//     this.image,
//   }) : role = _normalizeRole(role);

//   static String _normalizeRole(String role) {
//     final normalized = role.trim().toLowerCase();
//     return normalized.isEmpty ? 'user' : normalized;
//   }

//   bool get isAdmin => role == 'admin';

//   factory User.fromJson(Map<String, dynamic> json) {
//     final rawId = json['student_id'];
//     final String student_id = rawId is String
//         ? rawId
//         : (rawId != null ? rawId.toString() : ''); // Handle null and non-string cases

//     return User(
//       student_id: student_id,
//       username: (json['username'] ?? '').toString(),
//       // email: json['email']?.toString(),
//       fullname: (json['fullname'] ?? '').toString(),
//       role: (json['role'] ?? 'user').toString(),
//       image: json['image']?.toString(), // may be null - allowed
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'student_id': student_id,
//       'username': username,
//       // 'email': email,
//       'fullname': fullname,
//       'role': role,
//       'image': image,
//     };
//   }
// }

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

  bool get isAdmin => role == 'admin';

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

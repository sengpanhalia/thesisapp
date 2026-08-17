import 'package:thesisapp/model/user_detail.dart';

/// What `POST /api/v1/student_login.php` hands back on a successful sign-in.
///
/// The `session` is the student's signed credential — held by
/// [StudentSessionStore] and sent to `me.php`, nowhere else. [profile] is the
/// student's registry record, in the same field names the app has always read.
///
/// [passwordIsSharedDefault] comes straight from the server and is not about
/// this sign-in — it succeeded. It says the stored password is the one nearly
/// every student shares, so the app can tell the student their credential
/// protects nothing until the registry resets it.
class StudentLoginResult {
  const StudentLoginResult({
    required this.session,
    required this.expiresIn,
    required this.profile,
    required this.passwordIsSharedDefault,
  });

  final String session;

  /// Seconds until the session expires (the server sends 43200 — twelve hours).
  final int expiresIn;

  final UserDetail profile;
  final bool passwordIsSharedDefault;

  factory StudentLoginResult.fromJson(Map<String, dynamic> json) {
    final student = json['student'];

    return StudentLoginResult(
      session: json['session']?.toString().trim() ?? '',
      expiresIn: _int(json['expires_in']) ?? 0,
      profile: student is Map<String, dynamic>
          ? UserDetail.fromJson(student)
          : UserDetail.fromJson(const {}),
      passwordIsSharedDefault: json['password_is_shared_default'] == true,
    );
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Where the signed-in student's session lives on the device.
///
/// Distinct from [ApiTokenStore], and deliberately so. The API token is the
/// app's own credential, issued per device by the office, and it is the same
/// for whoever holds the phone. This is the *student's* credential — a signed
/// value that `POST /api/v1/student_login.php` mints and that says which student
/// is using the app. `GET /api/v1/me.php` reads it from the `X-Student-Session`
/// header; nothing else on the API will accept it.
///
/// It expires twelve hours after sign-in and cannot be revoked before then, so
/// the app treats a `401` from `me.php` as "sign in again" rather than a bug.
/// Cleared on sign-out, which is what stops the next person picking up the phone
/// from landing in the last student's account.
class StudentSessionStore {
  const StudentSessionStore._();

  static const String _prefsKey = 'usea_student_session';

  static String? _cached;
  static bool _loaded = false;

  /// The session, or empty when nobody is signed in.
  static Future<String> read() async {
    if (_loaded) return _cached ?? '';

    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_prefsKey);
    _loaded = true;

    return (_cached ?? '').trim();
  }

  /// The session only while it is still valid, or empty when it has expired.
  ///
  /// An expired session is cleared from storage so the app does not keep
  /// sending it and drawing 401s from the server.
  static Future<String> readValid() async {
    final session = await read();

    if (session.isEmpty) return '';

    if (_isExpired(session)) {
      await clear();
      return '';
    }

    return session;
  }

  /// True when the session is present but past its expiry time.
  static bool _isExpired(String session) {
    final parts = session.split('.');
    if (parts.length != 3 || parts[0] != 'usea_stu') return true;

    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = claims['exp'];

      if (exp == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now > (exp as int);
    } catch (_) {
      return true;
    }
  }

  static Future<void> save(String session) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = session.trim();

    if (trimmed.isEmpty) {
      await prefs.remove(_prefsKey);
      _cached = null;
    } else {
      await prefs.setString(_prefsKey, trimmed);
      _cached = trimmed;
    }

    _loaded = true;
  }

  static Future<void> clear() => save('');
}

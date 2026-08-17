import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';

/// The signed-in student's registry record — faculty, major, year, photo.
///
/// This used to sign in and read the record straight from the university's own
/// `api.usea.edu.kh`. It no longer does: sign-in and the profile both go
/// through this system's API now (`student_login.php` and `me.php`), which
/// reads the same registry tables server-side and never lets the app hold a
/// student password beyond the moment of sign-in.
///
/// [fetch] returns the record for whoever is signed in — the student number
/// comes from the saved session on the server, not from anything the app sends
/// — or null when the session has lapsed or the server cannot be reached, so a
/// profile screen shows what it already has rather than an error.
class StudentDirectory {
  const StudentDirectory._();

  static Future<UserDetail?> fetch() async {
    try {
      return await InventoryApi().myProfile();
    } on ApiException {
      // A lapsed session (401) or an unreachable server is not worth throwing
      // over here: the screens that call this already hold the record from
      // sign-in and simply keep it.
      return null;
    } catch (_) {
      return null;
    }
  }
}

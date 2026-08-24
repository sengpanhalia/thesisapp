import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/util/api_config.dart';

/// Where the API token lives on the device.
///
/// There is **one** API token for the whole system — `api.token` in the
/// server's `config/secrets.json` — and it does not rotate. Bake that single
/// value into the build with `--dart-define=USEA_API_TOKEN=…` and every install
/// carries the same permanent key. There is no per-device issuing any more; the
/// old "Settings ▸ API Tokens" screen was removed.
///
/// Precedence:
///
///  1. the token baked into the build (`USEA_API_TOKEN`), when there is one —
///     it is the permanent, operator-set key, so it wins. A stale token typed
///     into one device can never shadow it and force the "ask for a new one"
///     flow, which is what this ordering exists to prevent;
///  2. otherwise, a token saved on the device (the profile dialog) — for a dev
///     build shipped without a baked-in one.
///
/// Never a literal in the source: a token in the repository is a token in
/// everybody's checkout, and the API cannot tell the difference between the
/// operator using it and anyone else who read it.
class ApiTokenStore {
  const ApiTokenStore._();

  static const String _prefsKey = 'usea_api_token';

  static String? _cached;
  static bool _loaded = false;

  static Future<String> read() async {
    // The baked-in token is the one permanent key: it wins over anything saved
    // on the device, so the app never needs re-keying and a stale saved token
    // cannot lock it out.
    final built = ApiConfig.buildTimeToken.trim();
    if (built.isNotEmpty) {
      return built;
    }

    if (_loaded) return (_cached ?? '').trim();

    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_prefsKey);
    _loaded = true;

    return (_cached ?? '').trim();
  }

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = token.trim();

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

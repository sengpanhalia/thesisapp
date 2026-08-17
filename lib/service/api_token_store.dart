import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/util/api_config.dart';

/// Where the API token lives on the device.
///
/// The inventory system issues tokens under **Settings ▸ API Tokens** and
/// shows the key once, at creation, because only its SHA-256 hash is kept on
/// the server. Nothing here can recover a lost one — the operator issues a new
/// token and revokes the old.
///
/// Two ways in, in this order:
///
///  1. a token saved on the device, which is how a single build is pointed at
///     a different server or re-keyed after a revocation;
///  2. `--dart-define=USEA_API_TOKEN=usea_…` baked into the build.
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
    if (_loaded) return _cached ?? ApiConfig.buildTimeToken;

    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_prefsKey);
    _loaded = true;

    final stored = (_cached ?? '').trim();

    return stored.isNotEmpty ? stored : ApiConfig.buildTimeToken;
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

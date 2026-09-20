/// Where the app finds the USEA Smart Inventory REST API.
///
/// One place, one URL. The API is served from the inventory system's document
/// root, so the whole address ends in `/api/v1`. Override it at build time
/// rather than editing this file:
///
///   `flutter run --dart-define=USEA_API_BASE_URL=http://HOST_IP/USEA/USEA_Smart_Inventory_Management_System/api/v1`
///
/// **Default is the Android emulator's alias to host localhost** (`10.0.2.2`).
/// For a physical phone on the same WiFi, replace it with the host machine's
/// LAN IP (e.g. `http://192.168.1.50/...`).
///
/// The address was previously hardcoded to a development machine's LAN IP and
/// went stale whenever that machine's lease changed or the app was run from an
/// emulator, which cannot reach a private LAN address directly. `10.0.2.2` is
/// the emulator's special route to the host and is the right default for
/// development; a real deployment should use the university's hostname over
/// HTTPS, at which point this stops moving.
class ApiConfig {
  const ApiConfig._();

  static const String _defaultBaseUrl =
      'http://10.0.2.2/USEA/USEA_Smart_Inventory_Management_System/api/v1';

  static const String baseUrl = String.fromEnvironment(
    'USEA_API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  /// The bearer token compiled into this build, and **empty in the student
  /// build** — which is the point of it.
  ///
  /// It used to default to the live key written out in this file. That is one
  /// permanent token with an administrator's authority, and a value written
  /// here is not only in every checkout of this repository but in every APK
  /// handed to a student: unpack the bundle, run `strings`, read the key. Whoever
  /// has it can call `orders.php` with no session at all and list any
  /// classmate's reservations. The server's session-first rule (bootstrap.php)
  /// closes that only for callers who present a session — a bare token is still
  /// answered as its owner, so the key itself had to stop shipping.
  ///
  /// The student app never needed it. Signing in mints an HMAC-signed session
  /// (StudentSessionStore) that names one student, and every endpoint the app
  /// touches — catalogue, orders, profile, notifications — accepts that
  /// instead. Empty here costs a student nothing.
  ///
  /// Staff and bot builds still pass one, out of the gitignored
  /// `dart_defines.json` via `./run.sh`; ApiTokenStore explains the precedence.
  /// To rotate, change `api.token` in the server's `config/secrets.json` and
  /// that file — never this one. `test/api_config_test.dart` fails if the
  /// default stops being empty.
  static const String buildTimeToken = String.fromEnvironment(
    'USEA_API_TOKEN',
    defaultValue: '',
  );

  static Uri endpoint(String file, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return Uri.parse(
      '$base/$file',
    ).replace(queryParameters: (query == null || query.isEmpty) ? null : query);
  }

  /// The origin the API is served from — `http://host[:port]` — which is what
  /// a site-relative `image_url` has to be resolved against.
  static String get origin {
    final uri = Uri.parse(baseUrl);

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  /// Turns the API's `image_url` into something [Image.network] can fetch.
  ///
  /// The field is null whenever the catalogue has no picture for a row — which
  /// is every book in the university's own data today — and callers must show
  /// a placeholder rather than request a URL that would 404. When it is set it
  /// is usually absolute; a relative value is resolved against [origin].
  static String? resolveImageUrl(String? imageUrl) {
    final raw = (imageUrl ?? '').trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    return '$origin/${raw.startsWith('/') ? raw.substring(1) : raw}';
  }
}

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
      'http://192.168.3.3/USEA_Smart_Inventory_Management_System/api/v1';

  static const String baseUrl = String.fromEnvironment(
    'USEA_API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  /// The bearer token baked into this build.
  ///
  /// It must match `api.token` in the server's `config/secrets.json`. The server
  /// checks it with `hash_equals`, so even a whitespace mismatch is a refusal.
  ///
  /// **If the baked token ever drifts from the server, students are not locked
  /// out.** The server now falls back to the student's signed session whenever
  /// the bearer token is absent or invalid, so the catalogue, orders, profile
  /// and notifications keep working. The token only matters for staff or bot
  /// callers that rely on its authority.
  ///
  /// Override per build with `--dart-define=USEA_API_TOKEN=…`; to rotate, change
  /// `api.token` in `config/secrets.json` and the default below together.
  static const String buildTimeToken = String.fromEnvironment(
    'USEA_API_TOKEN',
    defaultValue: _bakedToken,
  );

  /// The current permanent token — `api.token` from the server's
  /// `config/secrets.json`.
  ///
  /// Keep this in sync with the server. When the server rotates the token,
  /// update this value and rebuild. Because the server falls back to student
  /// sessions for the student endpoints, a mismatch here does not break the
  /// student app — but a staff or bot build that depends on this token will
  /// need it corrected.
  static const String _bakedToken = '53a2b48099dc86710e266858c269aae33cc6f089c95ea6762e0cf7409c4d7831';

  static Uri endpoint(String file, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return Uri.parse('$base/$file').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  /// The origin the API is served from — `http://host[:port]` — which is what
  /// a site-relative `image_url` has to be resolved against.
  static String get origin {
    final uri = Uri.parse(baseUrl);

    return Uri(scheme: uri.scheme, host: uri.host, port: uri.hasPort ? uri.port : null)
        .toString();
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

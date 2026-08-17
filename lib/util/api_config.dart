/// Where the app finds the USEA Smart Inventory REST API.
///
/// One place, one URL. The API is served from the inventory system's document
/// root, so the whole address ends in `/api/v1`. Override it at build time
/// rather than editing this file:
///
///   flutter run --dart-define=USEA_API_BASE_URL=http://<host-ip>/USEA/USEA_Smart_Inventory_Management_System/api/v1
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

  /// The bearer token, supplied at build time. Empty by default: no token is
  /// ever committed to this repository. See [ApiTokenStore], which prefers a
  /// token the operator typed into the app over this one.
  static const String buildTimeToken = String.fromEnvironment('USEA_API_TOKEN');

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

import 'package:flutter_test/flutter_test.dart';
import 'package:thesisapp/util/api_config.dart';

void main() {
  test('every endpoint hangs off one base URL', () {
    expect(ApiConfig.baseUrl, endsWith('/api/v1'));
    expect(
      ApiConfig.endpoint('books.php').toString(),
      '${ApiConfig.baseUrl}/books.php',
    );
  });

  test('query parameters are encoded, not concatenated', () {
    final uri = ApiConfig.endpoint('books.php', {'year_level': 'Year 1'});

    expect(uri.queryParameters['year_level'], 'Year 1');
    // Dart writes a space as `+` in a query component. PHP reads that back as
    // a space — checked against the running server with both spellings of
    // `?q=Critical Thinking`, which return the same two books.
    expect(uri.toString(), contains('Year+1'));
  });

  test('no token is ever compiled into the repository', () {
    // A token comes from --dart-define or from the device. Finding one here
    // would mean it had been committed.
    expect(ApiConfig.buildTimeToken, isEmpty);
  });

  test('the app never points at the retired store API', () {
    expect(ApiConfig.baseUrl, isNot(contains('usea_store_api_official')));
  });

  group('resolveImageUrl', () {
    test('a catalogue row with no picture stays null', () {
      expect(ApiConfig.resolveImageUrl(null), isNull);
      expect(ApiConfig.resolveImageUrl(''), isNull);
      expect(ApiConfig.resolveImageUrl('null'), isNull);
    });

    test('an absolute URL is left alone', () {
      expect(
        ApiConfig.resolveImageUrl('https://mis.usea.edu.kh/uploads/1.png'),
        'https://mis.usea.edu.kh/uploads/1.png',
      );
    });

    test('a site-relative path is resolved against the API host', () {
      final resolved = ApiConfig.resolveImageUrl('/public/uploads/a.jpg');

      expect(resolved, startsWith(ApiConfig.origin));
      expect(resolved, endsWith('/public/uploads/a.jpg'));
    });
  });
}

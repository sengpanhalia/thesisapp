import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/service/api_token_store.dart';
import 'package:thesisapp/service/student_session_store.dart';
import 'package:thesisapp/util/api_config.dart';

/// The ways a call to the inventory API can fail, as the API actually fails.
enum ApiErrorKind {
  /// No token on the device and none built in — nothing to send.
  noToken,

  /// 401: missing, unknown or revoked token.
  unauthorized,

  /// 403: the token is live but not allowed to do this. Also what the server
  /// answers when it demands HTTPS and the call arrived over plain HTTP.
  forbidden,

  /// 404: no such book, order or student.
  notFound,

  /// 400: the request itself was wrong.
  badRequest,

  /// 409: a valid request the business rules refused — not enough stock, a
  /// book not approved for sale, an order already decided.
  conflict,

  /// 429: the per-address throttle.
  throttled,

  /// 405, and anything else in the 4xx range this app does not expect.
  unexpectedStatus,

  /// 5xx.
  server,

  /// The phone could not reach the server at all.
  network,

  /// It answered, but not before we gave up waiting.
  timeout,

  /// It answered with something that is not the JSON this API documents.
  malformed,
}

/// A failed API call, carrying both a key the app can translate and whatever
/// the server said about it.
class ApiException implements Exception {
  ApiException(this.kind, {this.serverMessage, this.statusCode});

  final ApiErrorKind kind;

  /// The API's own `{"error": "..."}` text. For a 409 this is the reason the
  /// request was refused — "Only 3 are free to reserve." — and is the only
  /// message worth showing, so it wins over the generic translation.
  final String? serverMessage;

  final int? statusCode;

  String get translationKey => switch (kind) {
    ApiErrorKind.noToken => 'api_error_no_token',
    ApiErrorKind.unauthorized => 'api_error_unauthorized',
    ApiErrorKind.forbidden => 'api_error_forbidden',
    ApiErrorKind.notFound => 'api_error_not_found',
    ApiErrorKind.badRequest => 'api_error_bad_request',
    ApiErrorKind.conflict => 'api_error_conflict',
    ApiErrorKind.throttled => 'api_error_throttled',
    ApiErrorKind.unexpectedStatus => 'api_error_server',
    ApiErrorKind.server => 'api_error_server',
    ApiErrorKind.network => 'api_error_network',
    ApiErrorKind.timeout => 'api_error_timeout',
    ApiErrorKind.malformed => 'api_error_malformed',
  };

  /// What to put in front of the student, in the language they chose.
  ///
  /// A refusal explains itself and that explanation is the actionable part, so
  /// it is shown as the server wrote it. Everything else — no network, a dead
  /// token, a throttle — means nothing to a student in the server's words, so
  /// those are the app's own translated sentences.
  String message(AppLocalizations? lang) {
    final fromServer = (serverMessage ?? '').trim();

    if (kind == ApiErrorKind.conflict && fromServer.isNotEmpty) {
      return fromServer;
    }

    final translated = lang?.translate(translationKey);

    if (translated != null && translated != translationKey) {
      return translated;
    }

    return fromServer.isNotEmpty ? fromServer : _fallbackEnglish;
  }

  String get _fallbackEnglish => switch (kind) {
    ApiErrorKind.noToken => 'This app has no API key yet. Ask the office for one.',
    ApiErrorKind.unauthorized => 'This app\'s key was refused. Ask the office for a new one.',
    ApiErrorKind.forbidden => 'This app is not allowed to do that.',
    ApiErrorKind.notFound => 'Not found.',
    ApiErrorKind.badRequest => 'That request was not accepted.',
    ApiErrorKind.conflict => 'The office refused that request.',
    ApiErrorKind.throttled => 'Too many requests. Please wait a moment.',
    ApiErrorKind.unexpectedStatus => 'The server had a problem. Try again later.',
    ApiErrorKind.server => 'The server had a problem. Try again later.',
    ApiErrorKind.network => 'Cannot reach the server. Check your connection.',
    ApiErrorKind.timeout => 'The server took too long to answer.',
    ApiErrorKind.malformed => 'The server sent something the app did not understand.',
  };

  @override
  String toString() =>
      'ApiException(${kind.name}, status: $statusCode, server: $serverMessage)';
}

/// Talks to `/api/v1`.
///
/// Every endpoint there wants `Authorization: Bearer <token>` and answers JSON,
/// including its failures, which are always `{"error": "..."}`. This turns
/// each one into either a decoded map or an [ApiException].
class ApiClient {
  ApiClient({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 20);

  final http.Client _client;
  final Duration _timeout;

  Future<Map<String, dynamic>> getJson(
    String file, {
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
  }) {
    return _send(() async {
      final headers = await _credentials();

      return _client
          .get(
            ApiConfig.endpoint(file, query),
            headers: {...headers, ...?extraHeaders},
          )
          .timeout(_timeout);
    });
  }

  Future<Map<String, dynamic>> postJson(
    String file,
    Map<String, dynamic> body, {
    Map<String, String>? extraHeaders,
  }) {
    return _send(() async {
      final headers = await _credentials();

      return _client
          .post(
            ApiConfig.endpoint(file),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
              ...?extraHeaders,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    });
  }

  /// Whatever credentials this phone actually has — and a student's has one.
  ///
  /// This used to demand a bearer token before it would send anything, and
  /// throw `noToken` when there was none. That was a staff assumption baked
  /// into a student's app: a bearer token is issued in the web application by
  /// an administrator and shown once, so a student who installs the app has
  /// nobody to get one from. They were asked to paste a `usea_…` key they
  /// could not possibly have, on the sign-in screen, before they could do
  /// anything at all.
  ///
  /// The student endpoints do not want one. `student_login.php` takes a number
  /// and a password; `me.php`, `books.php`, `categories.php` and `orders.php`
  /// accept the signed session that signing in mints. So both credentials are
  /// optional here and whichever exists is sent:
  ///
  ///   `Authorization`      a staff or bot build that was given a token
  ///   `X-Student-Session`  a student who has signed in
  ///
  /// Sending neither is allowed, and is exactly what signing in looks like. If
  /// an endpoint really does need a credential the server says so and says
  /// why, which is a better answer than this file guessing on its behalf.
  Future<Map<String, String>> _credentials() async {
    final headers = <String, String>{'Accept': 'application/json'};

    final token = (await ApiTokenStore.read()).trim();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final session = (await StudentSessionStore.read()).trim();
    if (session.isNotEmpty) {
      headers['X-Student-Session'] = session;
    }

    return headers;
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;

    try {
      response = await request();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(ApiErrorKind.timeout);
    } on SocketException {
      throw ApiException(ApiErrorKind.network);
    } on http.ClientException {
      throw ApiException(ApiErrorKind.network);
    } on HandshakeException {
      throw ApiException(ApiErrorKind.network);
    } catch (error) {
      /*
       * Anything else at all, turned into something the app can show.
       *
       * The five clauses above name the failures anybody thought of, and
       * everything else escaped as itself. The screens catch `ApiException`
       * and nothing wider, so an unforeseen error propagated out of the button
       * handler as an unhandled async error: the spinner stopped, no message
       * appeared, and the sign-in screen simply sat there. A user pressing
       * ចូលគណនី saw precisely nothing happen, twice, and had no way to find
       * out why — the worst failure this client can produce, because it looks
       * like the app ignoring them.
       *
       * Reading the saved credentials is inside this block too, which is how
       * a storage error on a phone could take the whole sign-in down without
       * a word. The server's own message is preserved where there is one so
       * the cause is not lost on its way to the surface.
       */
      throw ApiException(ApiErrorKind.network, serverMessage: error.toString());
    }

    // Decoded before the status is judged: a failure carries its reason in the
    // same JSON body as a success.
    Map<String, dynamic>? decoded;

    if (response.body.trim().isNotEmpty) {
      try {
        final value = jsonDecode(utf8.decode(response.bodyBytes));
        if (value is Map<String, dynamic>) decoded = value;
      } catch (_) {
        decoded = null;
      }
    }

    final serverMessage = decoded?['error']?.toString();
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (decoded == null) {
        throw ApiException(ApiErrorKind.malformed, statusCode: status);
      }

      return decoded;
    }

    throw ApiException(
      switch (status) {
        401 => ApiErrorKind.unauthorized,
        403 => ApiErrorKind.forbidden,
        404 => ApiErrorKind.notFound,
        400 => ApiErrorKind.badRequest,
        409 => ApiErrorKind.conflict,
        429 => ApiErrorKind.throttled,
        >= 500 => ApiErrorKind.server,
        _ => ApiErrorKind.unexpectedStatus,
      },
      serverMessage: serverMessage,
      statusCode: status,
    );
  }

  void close() => _client.close();
}

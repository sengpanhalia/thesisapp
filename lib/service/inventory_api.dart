import 'package:thesisapp/model/app_notification.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/model/book_category.dart';
import 'package:thesisapp/model/reservation.dart';
import 'package:thesisapp/model/student_login_result.dart';
import 'package:thesisapp/model/student_profile.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/student_session_store.dart';

/// How a student says they will pay. The API accepts these four and nothing
/// else; only `Cash` is recorded as paid, the rest start `PENDING` because a
/// wallet or card payment is not settled until the provider confirms it —
/// which this system does not do. The app must not present them as paid.
enum PaymentMethod {
  cash('Cash'),
  khqr('KHQR'),
  bakong('Bakong'),
  card('Card');

  const PaymentMethod(this.wireName);

  final String wireName;

  static PaymentMethod parse(String? value) {
    final raw = (value ?? '').trim().toLowerCase();

    return PaymentMethod.values.firstWhere(
      (method) => method.wireName.toLowerCase() == raw,
      orElse: () => PaymentMethod.cash,
    );
  }

  String get translationKey => switch (this) {
    PaymentMethod.cash => 'payment_cash',
    PaymentMethod.khqr => 'payment_khqr',
    PaymentMethod.bakong => 'payment_bakong',
    PaymentMethod.card => 'payment_card',
  };
}

/// The USEA Smart Inventory REST API, one method per thing the app needs.
///
/// Every call can throw [ApiException]; screens catch it and show
/// `error.message(lang)`.
class InventoryApi {
  InventoryApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ------------------------------------------------------------- catalogue --

  /// Books a student may buy: in stock and approved for sale by an admin.
  ///
  /// [yearLevel] takes `Year 1`…`Year 4`; books marked `All` always match. The
  /// university's own catalogue leaves the year blank on every row today, so
  /// filtering by year currently returns nothing — the app offers the filter
  /// but does not depend on it.
  ///
  /// [forMyYear] narrows the catalogue to the signed-in student's own year and
  /// semester, read live on the server from their enrolment (`mine=1`). It is
  /// for browsing, not search — a student searching by title wants to find a
  /// book whatever year it is filed under, so the search screen leaves it off.
  Future<List<Book>> books({
    String? search,
    String? yearLevel,
    bool forMyYear = false,
  }) async {
    final query = <String, String>{};

    final trimmedSearch = (search ?? '').trim();
    if (trimmedSearch.isNotEmpty) query['q'] = trimmedSearch;

    final trimmedYear = (yearLevel ?? '').trim();
    if (trimmedYear.isNotEmpty) query['year_level'] = trimmedYear;

    if (forMyYear) query['mine'] = '1';

    final json = await _client.getJson('books.php', query: query);

    return _list(json['books']).map(Book.fromJson).toList();
  }

  Future<Book?> refreshBook(Book book) async {
    if (book.id > 0) {
      try {
        final json = await _client.getJson(
          'books.php',
          query: {'id': book.id.toString()},
        );
        if (json['book'] is Map<String, dynamic>) {
          return Book.fromJson(json['book'] as Map<String, dynamic>);
        }
      } catch (_) {
        // Fall back to searching by code if direct ID lookup fails.
      }
    }

    if (book.code.trim().isEmpty) return null;

    final matches = await books(search: book.code);

    for (final candidate in matches) {
      if (candidate.id == book.id) return candidate;
    }

    return null;
  }

  // -------------------------------------------------------------- categories --

  /// The book categories a student can browse by — the catalogue's real ones,
  /// with a count of the books in each that are actually in stock and for sale.
  ///
  /// This is what the Category tab is built from. It used to group by
  /// `year_level`, which every book leaves blank, so it showed one heap; these
  /// four categories are the genuine split of the catalogue.
  ///
  /// [forMyYear] narrows the counts to the signed-in student's own year and
  /// semester, so every tile's number is of the books that student will
  /// actually see when they open it.
  Future<List<BookCategory>> categories({bool forMyYear = false}) async {
    final json = await _client.getJson(
      'categories.php',
      query: forMyYear ? {'mine': '1'} : null,
    );

    return _list(json['categories']).map(BookCategory.fromJson).toList();
  }

  /// The books in one category, filtered exactly as [books] filters — in stock
  /// and approved for sale. A book filed under several categories appears in
  /// each.
  Future<List<Book>> booksInCategory(int categoryId, {bool forMyYear = false}) async {
    final json = await _client.getJson(
      'categories.php',
      query: {
        'id': categoryId.toString(),
        if (forMyYear) 'mine': '1',
      },
    );

    return _list(json['books']).map(Book.fromJson).toList();
  }

  // --------------------------------------------------------------- student --

  /// Confirms a student number belongs to an active student.
  ///
  /// Throws [ApiException] with [ApiErrorKind.notFound] when it does not.
  Future<StudentProfile> student(String studentId) async {
    final json = await _client.getJson(
      'students.php',
      query: {'student_id': studentId.trim()},
    );

    final student = json['student'];

    if (student is! Map<String, dynamic>) {
      throw ApiException(ApiErrorKind.malformed);
    }

    return StudentProfile.fromJson(student);
  }

  // ----------------------------------------------------------------- sign-in --

  /// Signs a student in against the university's own `student_users`, through
  /// this system's API. On success the returned session is saved to
  /// [StudentSessionStore] and used by [myProfile] from then on.
  ///
  /// This replaces the old direct call to `api.usea.edu.kh`: sign-in now goes
  /// through the inventory API like everything else, and the app never posts a
  /// student password anywhere but here.
  ///
  /// Throws [ApiException] — `unauthorized` for a wrong number or password
  /// (the server does not say which), `forbidden` when the password is right
  /// but the student is no longer enrolled, `throttled` after too many tries.
  Future<StudentLoginResult> studentLogin({
    required String studentId,
    required String password,
  }) async {
    final json = await _client.postJson('student_login.php', {
      'student_id': studentId.trim(),
      'password': password,
    });

    final result = StudentLoginResult.fromJson(json);

    if (result.session.isEmpty) {
      throw ApiException(ApiErrorKind.malformed);
    }

    await StudentSessionStore.save(result.session);

    return result;
  }

  /// The signed-in student's own registry record, from `GET /me.php`.
  ///
  /// The student number is read from the saved session on the server, not sent
  /// as a parameter, so this can only ever return the signed-in student's own
  /// record. Replaces the old `api.usea.edu.kh` profile fetch.
  ///
  /// Throws `noToken`-like behaviour is not used here; an expired or missing
  /// session surfaces as [ApiErrorKind.unauthorized], which the caller should
  /// treat as "sign in again".
  Future<UserDetail> myProfile() async {
    final json = await _client.getJson(
      'me.php',
      query: {'include': 'profile'},
      extraHeaders: await _studentSessionHeader(),
    );

    final student = json['student'];

    if (student is! Map<String, dynamic>) {
      throw ApiException(ApiErrorKind.malformed);
    }

    return UserDetail.fromJson(student);
  }

  /// The signed-in student's own reservations, from `GET /me.php`.
  ///
  /// Same data as [reservationsFor], but scoped by the session rather than by a
  /// student number the caller passes in — so it cannot be pointed at anybody
  /// else. Newest first.
  Future<List<Reservation>> myReservations() async {
    final json = await _client.getJson(
      'me.php',
      query: {'include': 'orders'},
      extraHeaders: await _studentSessionHeader(),
    );

    return _sortedReservations(json['orders']);
  }

  /// The header that carries the student session, or an empty map when there is
  /// none — in which case `me.php` answers 401 and the app signs the student
  /// out, which is the right outcome.
  Future<Map<String, String>> _studentSessionHeader() async {
    final session = await StudentSessionStore.readValid();

    return session.isEmpty ? const {} : {'X-Student-Session': session};
  }

  // ---------------------------------------------------------- reservations --

  /// Holds copies of one title for a student.
  ///
  /// Stock is decided here, not on the device: the list the student was
  /// looking at may be a minute old, and the server locks the row, so a
  /// reservation can come back refused (409) because somebody else took the
  /// last copy. Read the answer, do not assume it.
  Future<Reservation> reserve({
    required int itemId,
    required int quantity,
    required String studentId,
    required PaymentMethod paymentMethod,
    String note = '',
  }) async {
    final json = await _client.postJson('orders.php', {
      'item_id': itemId,
      'qty': quantity,
      'student_id': studentId.trim(),
      'payment_method': paymentMethod.wireName,
      'note': note,
    });

    final order = json['order'];

    if (order is! Map<String, dynamic>) {
      throw ApiException(ApiErrorKind.malformed);
    }

    return Reservation.fromJson(order);
  }

  /// Holds a whole cart under one code, or holds none of it.
  ///
  /// The cart used to be emptied by calling [reserve] once per line, which
  /// produced one order code per book: a student who checked out four books
  /// carried four codes to the counter and gave finance four things to check
  /// for one transaction.
  ///
  /// It was also decided a line at a time, so a cart whose third book had just
  /// sold out left the student holding two reservations, no third, and two
  /// codes to explain. The server locks every title and refuses the lot if one
  /// is short — a slip printed for four books and honoured for three is a
  /// queue at the desk rather than a sale — so this either reserves everything
  /// or throws, and the cart is emptied only on success.
  ///
  /// **A basket may hold books and materials together, and comes back as more
  /// than one reservation.** They are two counters: the book room hands over
  /// books, the stock room hands over materials, and an order is the thing one
  /// room releases. So the server places one order per room, inside a single
  /// transaction — a shortage on either side reserves neither — and answers
  /// with both. Each carries the counter that will hand it over.
  ///
  /// `multi_order` is this build telling the server it can show several codes.
  /// Without it the server refuses a mixed basket outright, which is what it
  /// must keep doing for an older build: one that reads only `order` would send
  /// the student to the counter holding one of two codes, with no idea the
  /// other existed.
  Future<List<Reservation>> reserveAll({
    required List<({int itemId, int quantity})> items,
    required String studentId,
    required PaymentMethod paymentMethod,
    String note = '',
  }) async {
    if (items.isEmpty) {
      throw ApiException(ApiErrorKind.badRequest);
    }

    final json = await _client.postJson('orders.php', {
      'items': [
        for (final item in items) {'item_id': item.itemId, 'qty': item.quantity},
      ],
      'student_id': studentId.trim(),
      'payment_method': paymentMethod.wireName,
      'note': note,
      'multi_order': true,
    });

    final orders = json['orders'];

    if (orders is List) {
      final placed = [
        for (final entry in orders.whereType<Map>())
          Reservation.fromJson(Map<String, dynamic>.from(entry)),
      ];

      if (placed.isNotEmpty) {
        return placed;
      }
    }

    // A server too old to split a basket answers with `order` alone, and for a
    // single-kind basket that is the same reservation under another name.
    final order = json['order'];

    if (order is! Map<String, dynamic>) {
      throw ApiException(ApiErrorKind.malformed);
    }

    return [Reservation.fromJson(order)];
  }

  /// Every reservation this student has made, newest first.
  Future<List<Reservation>> reservationsFor(String studentId) async {
    final json = await _client.getJson(
      'orders.php',
      query: {'student_id': studentId.trim()},
    );

    return _sortedReservations(json['orders']);
  }

  static List<Reservation> _sortedReservations(dynamic value) {
    return _list(value).map(Reservation.fromJson).toList()
      ..sort((a, b) {
        final left = a.createdAt;
        final right = b.createdAt;

        if (left != null && right != null) return right.compareTo(left);
        if (left == null && right == null) return b.id.compareTo(a.id);

        return left == null ? 1 : -1;
      });
  }

  /// One reservation by its code. The counter moves the status forward on the
  /// web screens, so this is the app's only view of it — poll, don't cache.
  Future<Reservation> reservation(String code) async {
    final json = await _client.getJson(
      'orders.php',
      query: {'code': code.trim()},
    );

    final order = json['order'];

    if (order is! Map<String, dynamic>) {
      throw ApiException(ApiErrorKind.malformed);
    }

    return Reservation.fromJson(order);
  }

  /// Releases the held copies. The student number must match the reservation,
  /// so one student cannot cancel another's.
  Future<void> cancelReservation({
    required String code,
    required String studentId,
  }) async {
    await _client.postJson('orders.php', {
      'action': 'cancel',
      'code': code.trim(),
      'student_id': studentId.trim(),
    });
  }

  // --------------------------------------------------------- notifications --

  /// Everything the counter has told this student, newest first.
  ///
  /// Scoped by the session, not by a student number — the endpoint reads the
  /// number out of the signed session on this branch and ignores anything the
  /// caller sends, so one student cannot read another's messages.
  Future<NotificationInbox> notifications({int limit = 50}) async {
    final json = await _client.getJson(
      'notifications.php',
      query: {'limit': '$limit'},
      extraHeaders: await _studentSessionHeader(),
    );

    return NotificationInbox(
      messages: _list(json['notifications'])
          .map(AppNotification.fromJson)
          .toList(),
      unread: _int(json['unread']) ?? 0,
    );
  }

  /// Marks one message read, or every one of them when [id] is null.
  ///
  /// Returns the unread count the server is left holding, so the badge follows
  /// the server rather than being decremented here and drifting.
  Future<int> markNotificationsRead({int? id}) async {
    final json = await _client.postJson('notifications.php', {
      'action': 'read',
      if (id != null) 'id': id,
    }, extraHeaders: await _studentSessionHeader());

    return _int(json['unread']) ?? 0;
  }

  // ---------------------------------------------------------------- devices --

  /// Tells the server where to deliver this student's notifications.
  ///
  /// Called after signing in and again whenever Firebase rotates the token,
  /// which it does while the app is running. Registering the same token twice
  /// is a no-op on the server, which is what makes it safe to call this often.
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    await _client.postJson('devices.php', {
      'token': token.trim(),
      'platform': platform,
    }, extraHeaders: await _studentSessionHeader());
  }

  /// Stops notifications being delivered to this handset, on sign-out.
  ///
  /// Phones get shared and sold, and the next message must not land on a lock
  /// screen belonging to somebody else naming this student's order.
  Future<void> forgetDevice(String token) async {
    await _client.postJson('devices.php', {
      'action': 'forget',
      'token': token.trim(),
    }, extraHeaders: await _studentSessionHeader());
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}

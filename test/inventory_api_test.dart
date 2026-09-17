import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/model/book_category.dart';
import 'package:thesisapp/model/reservation.dart';
import 'package:thesisapp/model/student_login_result.dart';
import 'package:thesisapp/model/student_profile.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';

/// The payloads below are copied from real responses of the running system at
/// http://localhost/USEA/USEA_Smart_Inventory_Management_System/api/v1 — not
/// from the documentation, which differs from the server in places.
void main() {
  group('Book', () {
    test('reads a book as books.php really sends one', () {
      final book = Book.fromJson(
        jsonDecode('''
        {
          "id": 1, "code": "0001CT",
          "title": "Critical Thinking", "title_kh": "ការគិតត្រិះរិះពិចារណា",
          "author": "", "publisher": "", "isbn": "", "year_level": "",
          "price": 2, "available_qty": 22, "unit": "ក្បាល ", "image_url": null
        }''') as Map<String, dynamic>,
      );

      expect(book.id, 1);
      expect(book.code, '0001CT');
      // The API sends 2, not 2.0 — JSON drops the trailing zero.
      expect(book.price, 2.0);
      expect(book.availableQty, 22);
      expect(book.imageUrl, isNull);
      expect(book.isOutOfStock, isFalse);
    });

    test('a missing price is unknown, not free', () {
      final book = Book.fromJson({'id': 4, 'code': 'BOK-4', 'title': 'X'});

      expect(book.price, isNull);
      expect(book.hasPrice, isFalse);
      expect(formatMoney(book.price), '—');
      // Availability the catalogue did not state must not read as sold out.
      expect(book.availableQty, isNull);
      expect(book.isOutOfStock, isFalse);
    });

    test('formats money to two places', () {
      expect(formatMoney(10), r'$10.00');
      expect(formatMoney(1.125), r'$1.13');
    });

    test('picks the title for the language, falling back', () {
      const both = Book(
        id: 1,
        code: 'C',
        title: 'English',
        titleKh: 'ខ្មែរ',
        author: '',
        publisher: '',
        isbn: '',
        yearLevel: '',
        unit: '',
        price: null,
        availableQty: null,
        imageUrl: null,
      );

      expect(both.titleFor(khmer: true), 'ខ្មែរ');
      expect(both.titleFor(khmer: false), 'English');
    });
  });

  group('Reservation', () {
    final json =
        jsonDecode('''
    {
      "id": 1027, "code": "ORD-001027", "status": "PENDING",
      "student_id": "1576826673164", "student_name": "SREYHEANG POL",
      "item_id": 1, "item_code": "1", "title": "Paper A4",
      "quantity": 1, "unit_price": 0, "total_price": 0,
      "payment_method": "KHQR", "note": "", "created_at": "2026-08-15 22:39:56"
    }''')
            as Map<String, dynamic>;

    test('reads one as orders.php sends it', () {
      final reservation = Reservation.fromJson(json);

      expect(reservation.code, 'ORD-001027');
      expect(reservation.status, ReservationStatus.pending);
      expect(reservation.quantity, 1);
      // A MySQL datetime is a space short of ISO-8601.
      expect(reservation.createdAt, DateTime(2026, 8, 15, 22, 39, 56));
    });

    test('orders start as unpaid (PENDING) until confirmed', () {
      expect(Reservation.fromJson(json).isPaid, isFalse);
      expect(
        Reservation.fromJson({...json, 'payment_method': 'Cash'}).isPaid,
        isFalse,
      );
      expect(
        Reservation.fromJson({
          ...json,
          'payment_method': 'Cash',
          'status': 'CONFIRMED',
        }).isPaid,
        isTrue,
      );
      expect(
        Reservation.fromJson({
          ...json,
          'payment_method': 'Cash',
          'status': 'COLLECTED',
        }).isPaid,
        isTrue,
      );
      expect(
        Reservation.fromJson({
          ...json,
          'payment_method': 'Cash',
          'payment_status': 'PAID',
        }).isPaid,
        isTrue,
      );
      expect(
        Reservation.fromJson({
          ...json,
          'payment_method': 'Cash',
          'payment_status': 'PAID',
          'status': 'CANCELLED',
        }).isPaid,
        isFalse,
      );
    });

    test('a status the app does not know does not crash it', () {
      final reservation = Reservation.fromJson({...json, 'status': 'WHATEVER'});

      expect(reservation.status, ReservationStatus.unknown);
      expect(reservation.status.isCancellable, isFalse);
    });

    test('reads a basket as orders.php now sends one', () {
      // One code, three titles. The flat fields are the first line and the
      // basket's totals, kept so screens written before baskets still read.
      final order = Reservation.fromJson(
        jsonDecode('''
        {
          "id": 1216, "code": "ORD-USEA-85714C79", "status": "PENDING",
          "student_id": "BSR170342", "student_name": "Rithy Student",
          "payment_method": "KHQR", "note": "",
          "created_at": "2026-08-17 13:24:02",
          "quantity": 4, "total_price": 6.51, "line_count": 3,
          "lines": [
            {"id": 1216, "item_id": 1, "item_code": "0001CT",
             "title": "Critical Thinking", "title_kh": "ការគិតត្រិះរិះពិចារណា",
             "quantity": 2, "unit_price": 2, "total_price": 4},
            {"id": 1217, "item_id": 9, "item_code": "0009IM",
             "title": "Investment Management", "title_kh": "ការគ្រប់គ្រងការវិនិយោគ",
             "quantity": 1, "unit_price": 1.13, "total_price": 1.13},
            {"id": 1218, "item_id": 14, "item_code": "0014OM",
             "title": "Office Management", "title_kh": "ការគ្រប់គ្រងការិយាល័យ",
             "quantity": 1, "unit_price": 1.38, "total_price": 1.38}
          ],
          "item_id": 1, "item_code": "0001CT", "title": "Critical Thinking",
          "unit_price": 2
        }''') as Map<String, dynamic>,
      );

      expect(order.code, 'ORD-USEA-85714C79');
      expect(order.isBasket, isTrue);
      expect(order.lines, hasLength(3));
      expect(order.asLines, hasLength(3));

      // The totals are the whole basket, not the first line — that is what a
      // student checks their money against.
      expect(order.quantity, 4);
      expect(order.totalPrice, 6.51);

      expect(order.lines[1].itemCode, '0009IM');
      expect(order.lines[1].title(khmer: true), 'ការគ្រប់គ្រងការវិនិយោគ');
      expect(order.lines[1].title(khmer: false), 'Investment Management');
    });

    test('a one-title order is the same thing with one line', () {
      final order = Reservation.fromJson(
        jsonDecode('''
        {
          "id": 3, "code": "ORD-USEA-1A2B3C4D", "status": "PENDING",
          "student_id": "BSR170342", "student_name": "Rithy Student",
          "payment_method": "Cash", "note": "",
          "created_at": "2026-08-06 06:45:41",
          "quantity": 1, "total_price": 10.0, "line_count": 1,
          "lines": [
            {"id": 3, "item_id": 8, "item_code": "BOK-0004",
             "title": "Khmer Literature Reader", "title_kh": "",
             "quantity": 1, "unit_price": 10.0, "total_price": 10.0}
          ],
          "item_id": 8, "item_code": "BOK-0004",
          "title": "Khmer Literature Reader", "unit_price": 10.0
        }''') as Map<String, dynamic>,
      );

      expect(order.isBasket, isFalse);
      expect(order.asLines, hasLength(1));
      expect(order.asLines.first.title(khmer: true), 'Khmer Literature Reader');
    });

    test('a server too old to send lines still renders', () {
      // The shape orders.php answered before baskets existed. asLines rebuilds
      // the one line from the flat fields, so no screen handles two shapes.
      final order = Reservation.fromJson({
        'id': 3,
        'code': 'ORD-000001',
        'status': 'PENDING',
        'item_id': 8,
        'item_code': 'BOK-0004',
        'title': 'Khmer Literature Reader',
        'quantity': 2,
        'unit_price': 10.0,
        'total_price': 20.0,
        'payment_method': 'Cash',
      });

      expect(order.lines, isEmpty);
      expect(order.isBasket, isFalse);
      expect(order.asLines, hasLength(1));
      expect(order.asLines.first.quantity, 2);
      expect(order.asLines.first.itemCode, 'BOK-0004');
    });

    test('only a live reservation may be cancelled', () {
      expect(ReservationStatus.pending.isCancellable, isTrue);
      expect(ReservationStatus.readyForPickup.isCancellable, isTrue);
      expect(ReservationStatus.collected.isCancellable, isFalse);
      expect(ReservationStatus.cancelled.isCancellable, isFalse);
    });
  });

  test('StudentProfile reads students.php', () {
    final student = StudentProfile.fromJson(
      jsonDecode('''
      {"student_id": "1576826673164", "name": "SREYHEANG POL",
       "name_kh": "ប៉ុល ស្រីហ៊ាង", "year_level": ""}''')
          as Map<String, dynamic>,
    );

    expect(student.studentId, '1576826673164');
    expect(student.nameFor(khmer: true), 'ប៉ុល ស្រីហ៊ាង');
    expect(student.yearLevel, isEmpty);
  });

  group('ApiException', () {
    test('shows the server''s own words for a refusal', () {
      final error = ApiException(
        ApiErrorKind.conflict,
        serverMessage: 'Only 76 are free to reserve.',
        statusCode: 409,
      );

      // No AppLocalizations in a unit test; the refusal must still be the
      // sentence the server wrote, because that is the actionable part.
      expect(error.message(null), 'Only 76 are free to reserve.');
    });

    test('translates the failures a server message cannot explain', () {
      expect(
        ApiException(ApiErrorKind.throttled).translationKey,
        'api_error_throttled',
      );
      expect(
        ApiException(ApiErrorKind.unauthorized).translationKey,
        'api_error_unauthorized',
      );
      expect(
        ApiException(ApiErrorKind.network).translationKey,
        'api_error_network',
      );
    });
  });

  group('PaymentMethod', () {
    test('sends the exact names the API accepts', () {
      expect(PaymentMethod.cash.wireName, 'Cash');
      expect(PaymentMethod.khqr.wireName, 'KHQR');
      expect(PaymentMethod.bakong.wireName, 'Bakong');
      expect(PaymentMethod.card.wireName, 'Card');
    });

    test('parses back, defaulting to cash', () {
      expect(PaymentMethod.parse('khqr'), PaymentMethod.khqr);
      expect(PaymentMethod.parse('nonsense'), PaymentMethod.cash);
    });
  });

  group('BookCategory', () {
    // A row exactly as GET /categories.php sends it — many carry only a Khmer
    // name, with `name` falling back to it on the server.
    test('reads a category as categories.php really sends one', () {
      final category = BookCategory.fromJson(
        jsonDecode('''
        {
          "id": 3, "name": "សៀវភៅបោះពុម្ពសខ្មៅ",
          "name_kh": "សៀវភៅបោះពុម្ពសខ្មៅ", "book_count": 120
        }''') as Map<String, dynamic>,
      );

      expect(category.id, 3);
      expect(category.bookCount, 120);
      // With no distinct English name the language pick lands on Khmer either
      // way, which is what a Khmer-only category should do.
      expect(category.nameFor(khmer: true), 'សៀវភៅបោះពុម្ពសខ្មៅ');
      expect(category.nameFor(khmer: false), 'សៀវភៅបោះពុម្ពសខ្មៅ');
    });

    test('picks the name for the language when both exist', () {
      const category = BookCategory(
        id: 1,
        name: 'Original copies',
        nameKh: 'សៀវភៅច្បាប់ដើម',
        bookCount: 39,
      );

      expect(category.nameFor(khmer: false), 'Original copies');
      expect(category.nameFor(khmer: true), 'សៀវភៅច្បាប់ដើម');
    });
  });

  group('StudentLoginResult', () {
    // A response exactly as POST /student_login.php sends one.
    test('reads the session, the flag and the profile', () {
      final result = StudentLoginResult.fromJson(
        jsonDecode('''
        {
          "session": "usea_stu.abc.def",
          "expires_at": "2026-08-16 22:41:03",
          "expires_in": 43200,
          "student": {
            "student_id": "ASR130047", "name_kh": "រ", "name_en": "R",
            "faculty_name": "Law", "year_name": "ឆ្នាំទី 4",
            "status_name": "ACTIVE", "profile_pic": null
          },
          "password_is_shared_default": true
        }''') as Map<String, dynamic>,
      );

      expect(result.session, 'usea_stu.abc.def');
      expect(result.expiresIn, 43200);
      expect(result.passwordIsSharedDefault, isTrue);
      expect(result.profile.student_id, 'ASR130047');
      expect(result.profile.faculty_name, 'Law');
    });

    test('a missing shared-default flag is not a warning', () {
      final result = StudentLoginResult.fromJson(
        jsonDecode('''
        {"session": "usea_stu.x.y", "expires_in": 43200, "student": {}}''')
            as Map<String, dynamic>,
      );

      expect(result.passwordIsSharedDefault, isFalse);
      // A missing student object must not crash the parse.
      expect(result.profile.student_id, '');
    });
  });
}

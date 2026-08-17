import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesisapp/model/app_notification.dart';

/// The payloads below are copied from real responses of the running system at
/// http://localhost/USEA/USEA_Smart_Inventory_Management_System/api/v1 —
/// `GET /notifications.php` with a student session.
void main() {
  group('AppNotification', () {
    test('reads one as notifications.php really sends it', () {
      final message = AppNotification.fromJson(
        jsonDecode('''
        {
          "id": 12,
          "title": "Your books are ready",
          "title_kh": "សៀវភៅរួចរាល់សម្រាប់ទទួល",
          "body": "Order ORD-USEA-EAD90AAB is ready. Come to the book counter.",
          "body_kh": "ការកម្ម៉ង់ ORD-USEA-EAD90AAB រួចរាល់ហើយ។",
          "type": "order_update",
          "order_code": "ORD-USEA-EAD90AAB",
          "broadcast": false,
          "is_read": false,
          "read_at": null,
          "created_at": "2026-08-17 13:24:02"
        }''') as Map<String, dynamic>,
      );

      expect(message.id, 12);
      expect(message.orderCode, 'ORD-USEA-EAD90AAB');
      expect(message.isRead, isFalse);
      expect(message.isBroadcast, isFalse);
      expect(message.opensOrder, isTrue);
      expect(message.createdAt, DateTime.parse('2026-08-17T13:24:02'));
    });

    test('the phone picks the language, because the server cannot', () {
      final message = AppNotification.fromJson({
        'id': 1,
        'title': 'Your books are ready',
        'title_kh': 'សៀវភៅរួចរាល់សម្រាប់ទទួល',
        'body': 'Come to the counter.',
        'body_kh': 'សូមអញ្ជើញមកទទួល។',
      });

      expect(message.title(khmer: true), 'សៀវភៅរួចរាល់សម្រាប់ទទួល');
      expect(message.title(khmer: false), 'Your books are ready');
      expect(message.body(khmer: true), 'សូមអញ្ជើញមកទទួល។');
    });

    test('a message typed in one language only still shows', () {
      // What a member of staff sending one by hand from the counter produces.
      final english = AppNotification.fromJson({
        'id': 2,
        'title': 'Payment received',
        'title_kh': '',
        'body': 'Thank you.',
        'body_kh': '',
      });

      expect(english.title(khmer: true), 'Payment received');
      expect(english.body(khmer: true), 'Thank you.');

      final khmer = AppNotification.fromJson({
        'id': 3,
        'title': '',
        'title_kh': 'បានទទួលប្រាក់',
        'body': '',
        'body_kh': 'សូមអរគុណ។',
      });

      expect(khmer.title(khmer: false), 'បានទទួលប្រាក់');
      expect(khmer.body(khmer: false), 'សូមអរគុណ។');
    });

    test('a message about nothing in particular does not open an order', () {
      final notice = AppNotification.fromJson({
        'id': 4,
        'title': 'The counter closes at 3pm today',
        'type': 'info',
        'order_code': null,
        'broadcast': true,
      });

      expect(notice.isBroadcast, isTrue);
      expect(notice.orderCode, isNull);
      expect(notice.opensOrder, isFalse);
    });

    test('an order_update with no code cannot be opened either', () {
      // Defensive: the type alone is not enough to navigate on.
      final message = AppNotification.fromJson({
        'id': 5,
        'title': 'Something happened',
        'type': 'order_update',
        'order_code': '',
      });

      expect(message.opensOrder, isFalse);
    });

    test('a field the app has never seen does not crash it', () {
      final message = AppNotification.fromJson({'id': '7'});

      expect(message.id, 7);
      expect(message.title(khmer: true), '');
      expect(message.isRead, isFalse);
      expect(message.createdAt, isNull);
    });
  });

  group('NotificationInbox', () {
    test('an empty inbox has nothing and owes nothing', () {
      const inbox = NotificationInbox.empty();

      expect(inbox.messages, isEmpty);
      expect(inbox.unread, 0);
    });
  });
}

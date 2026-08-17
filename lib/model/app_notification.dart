/// One message the counter has left for this student.
///
/// `/api/v1/notifications.php` returns these. A message is stored on the server
/// whether or not the push ever reached the handset, so this list is the truth
/// and the banner in the notification tray is only a nudge towards it: a phone
/// that was flat, switched off or freshly reinstalled finds everything here.
///
/// Both languages arrive on every message. The server composes it when a member
/// of staff moves the order — possibly hours before this screen is opened — and
/// has no way of knowing which language the phone is set to, so it sends both
/// and the choice is made here. See [title] and [body].
class AppNotification {
  const AppNotification({
    required this.id,
    required this.titleEn,
    required this.titleKh,
    required this.bodyEn,
    required this.bodyKh,
    required this.type,
    required this.orderCode,
    required this.isBroadcast,
    required this.isRead,
    required this.createdAt,
  });

  final int id;

  final String titleEn;
  final String titleKh;
  final String bodyEn;
  final String bodyKh;

  /// What tapping it should do. `order_update` carries an [orderCode] and opens
  /// that reservation; anything else is read where it stands.
  final String type;

  /// The reservation this is about, or null for a message that is not about one.
  final String? orderCode;

  /// A notice sent to every student rather than to this one.
  ///
  /// The server cannot record one student having read a message that is a
  /// single shared row, so a broadcast stays unread on the badge. It is worth
  /// knowing about here so the screen does not offer to mark it read and then
  /// appear to do nothing.
  final bool isBroadcast;

  final bool isRead;
  final DateTime? createdAt;

  /// The title in the language asked for, falling back to whichever exists.
  ///
  /// Falling back rather than showing an empty line: a message sent by hand
  /// from the counter may well have been typed in one language only, and a
  /// blank notification is worse than one in the other language.
  String title({required bool khmer}) => _pick(titleKh, titleEn, khmer: khmer);

  String body({required bool khmer}) => _pick(bodyKh, bodyEn, khmer: khmer);

  static String _pick(String khmer_, String english, {required bool khmer}) {
    final first = khmer ? khmer_ : english;

    if (first.trim().isNotEmpty) return first.trim();

    return (khmer ? english : khmer_).trim();
  }

  /// True when this is about a reservation the app can open.
  bool get opensOrder =>
      type == 'order_update' && (orderCode ?? '').trim().isNotEmpty;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _int(json['id']) ?? 0,
      titleEn: _text(json['title']),
      titleKh: _text(json['title_kh']),
      bodyEn: _text(json['body']),
      bodyKh: _text(json['body_kh']),
      type: _text(json['type']),
      orderCode: _text(json['order_code']).isEmpty
          ? null
          : _text(json['order_code']),
      isBroadcast: json['broadcast'] == true,
      isRead: json['is_read'] == true,
      createdAt: _dateTime(json['created_at']),
    );
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  /// `2026-08-06 06:45:41` — a MySQL datetime, which is a space short of ISO.
  static DateTime? _dateTime(dynamic value) {
    final raw = (value?.toString() ?? '').trim();

    if (raw.isEmpty) return null;

    return DateTime.tryParse(raw.contains('T') ? raw : raw.replaceFirst(' ', 'T'));
  }
}

/// A page of messages, with the count the bell badge shows.
class NotificationInbox {
  const NotificationInbox({required this.messages, required this.unread});

  const NotificationInbox.empty() : messages = const [], unread = 0;

  final List<AppNotification> messages;
  final int unread;
}

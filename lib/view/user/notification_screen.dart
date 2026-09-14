import 'package:flutter/material.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/app_notification.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/service/notification_service.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/order_details_screen.dart';

/// What the counter has told this student.
///
/// This used to be built out of `GET /orders.php` and said so: the inventory
/// API had no notifications, nothing stored a message, nothing marked one read,
/// and there was nowhere to register a push token against. So the screen showed
/// the student's live reservations and called them news.
///
/// That could only ever say what was true at the moment it was opened. A
/// reservation that was confirmed and then collected showed as collected, and
/// the confirmation — the thing the student wanted to be told — had never been
/// recorded anywhere. Anything that was not about an order had nowhere to live
/// at all.
///
/// It now reads `GET /notifications.php`, which is a real inbox: a row is
/// written when the counter moves the order, it stays written, and the push to
/// the handset is a nudge towards it rather than the message itself. A phone
/// that was flat or switched off finds everything waiting here.
class NotificationScreen extends StatefulWidget {
  final dynamic userId;

  const NotificationScreen({super.key, this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final InventoryApi _api = InventoryApi();

  List<AppNotification> _messages = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isMarkingAll = false;

  bool get _hasUnread => _messages.any((m) => !m.isRead);

  @override
  void initState() {
    super.initState();
    NotificationService.removeBadge();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final inbox = await _api.notifications();
      if (!mounted) return;

      setState(() {
        _messages = inbox.messages;
        _loadError = null;
        _isLoading = false;
      });

      await NotificationService.updateBadgeCount(inbox.unread);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message(AppLocalizations.of(context));
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (!_hasUnread || _isMarkingAll) return;

    setState(() {
      _isMarkingAll = true;
      _messages = [
        for (final m in _messages) m.copyWith(isRead: true),
      ];
    });

    try {
      final unread = await _api.markNotificationsRead();
      await NotificationService.updateBadgeCount(unread);
    } on ApiException {
      // The list is what matters, and it is already updated on screen.
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  Future<void> _markAsRead(AppNotification message) async {
    if (message.isRead) return;

    setState(() {
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRead: true);
      }
    });

    if (!message.isBroadcast) {
      try {
        final unread = await _api.markNotificationsRead(id: message.id);
        await NotificationService.updateBadgeCount(unread);
      } on ApiException {
        // Swallowed
      }
    }
  }

  /// Opens the reservation a message is about.
  ///
  /// The message carries an order code rather than the reservation itself, so
  /// it is fetched here. That is one request when a student taps a message, and
  /// it is a deliberate trade against storing a copy of the order inside the
  /// notification: the counter keeps moving the status after the message is
  /// written, and a copy would show the student what was true when they were
  /// told rather than what is true when they look.
  Future<void> _open(AppNotification message) async {
    final code = (message.orderCode ?? '').trim();

    if (code.isEmpty) return;

    final lang = AppLocalizations.of(context);

    try {
      final reservation = await _api.reservation(code);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(order: reservation),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message(lang))));
    }
  }

  /// Shows a bottom sheet that slides up from the bottom with full notification details.
  void _showDetail(AppNotification message, bool khmer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationDetailSheet(
        message: message,
        khmer: khmer,
        icon: _icon(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final khmer = Localizations.localeOf(context).languageCode == 'km';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate('notifications'),
          style: TextStyle(
            fontFamily: getFontFamily(context),
            fontSize: fontAppBar,
            color: TitleColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _hasUnread && !_isMarkingAll ? _markAllAsRead : null,
            style: TextButton.styleFrom(
              foregroundColor: GreenColor,
              disabledForegroundColor: TextSoftColor.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              lang.translate('mark_all_as_read'),
              style: TextStyle(
                fontFamily: getFontFamily(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: gradientColor(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: _messages.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  _loadError ??
                                      lang.translate('no_notifications'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: getFontFamily(context),
                                    fontSize: fontSubtitle,
                                    color: TextSoftColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _messages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _card(_messages[index], khmer, context),
                        ),
                ),
        ),
      ),
    );
  }

  Widget _card(AppNotification message, bool khmer, BuildContext context) {
    // Unread is what the student came to see, so it is what the card marks.
    final isNew = !message.isRead;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _markAsRead(message);
        if (message.opensOrder) {
          _open(message);
        } else {
          _showDetail(message.copyWith(isRead: true), khmer);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNew ? GreenColor : StrokeSearchBar,
            width: isNew ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon(message), color: isNew ? GreenColor : IconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.title(khmer: khmer),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontText,
                      fontWeight: FontWeight.w700,
                      color: TitleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.body(khmer: khmer),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontText,
                      color: TextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: TextSoftColor,
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(AppNotification message) {
    if (message.isBroadcast) return Icons.campaign_rounded;

    return message.opensOrder
        ? Icons.inventory_rounded
        : Icons.notifications_rounded;
  }
}

// ---------------------------------------------------------------------------
// Bottom-sheet detail panel
// ---------------------------------------------------------------------------

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({
    required this.message,
    required this.khmer,
    required this.icon,
  });

  final AppNotification message;
  final bool khmer;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isNew = !message.isRead;
    final createdAt = message.createdAt;

    String? formattedDate;
    if (createdAt != null) {
      final local = createdAt.toLocal();
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      formattedDate = '${local.day}/${local.month}/${local.year}  $h:$m';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: StrokeSearchBar,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // scrollable body — shrinks to content, scrolls if very tall
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24, 16, 24,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // icon circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isNew
                          ? GreenColor.withOpacity(0.1)
                          : GBackground3,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: isNew ? GreenColor : IconColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // title
                  Text(
                    message.title(khmer: khmer),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontHeadTitle,
                      fontWeight: FontWeight.w700,
                      color: TitleColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // body
                  Text(
                    message.body(khmer: khmer),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontSubtitle,
                      color: TextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(color: StrokeSearchBar),
                  const SizedBox(height: 16),

                  // type row
                  _detailRow(
                    context,
                    rowIcon: Icons.label_outline_rounded,
                    label: 'Type',
                    value: message.isBroadcast
                        ? 'Broadcast'
                        : message.type
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w.isEmpty
                                ? ''
                                : '${w[0].toUpperCase()}${w.substring(1)}')
                            .join(' '),
                  ),

                  if (formattedDate != null) ...[
                    const SizedBox(height: 12),
                    _detailRow(
                      context,
                      rowIcon: Icons.access_time_rounded,
                      label: 'Date',
                      value: formattedDate,
                    ),
                  ],

                  if ((message.orderCode ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _detailRow(
                      context,
                      rowIcon: Icons.receipt_long_rounded,
                      label: 'Order',
                      value: message.orderCode!,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // close button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ButtonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontFamily: getFontFamily(context),
                          fontSize: fontSubtitle,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData rowIcon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(rowIcon, size: 18, color: GreenColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: getFontFamily(context),
                  fontSize: 11,
                  color: TextSoftColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: getFontFamily(context),
                  fontSize: fontText,
                  color: TitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

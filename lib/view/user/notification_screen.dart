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

      /*
       * Opening the screen is reading them.
       *
       * Marked after the list is on screen rather than before it, so the
       * student still sees which ones were new — the unread marker is drawn
       * from the list already fetched, and only the server's count moves.
       * Failures are swallowed: a badge that is one out is not worth an error
       * message over a list that loaded perfectly well.
       */
      await _markEverythingRead();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message(AppLocalizations.of(context));
        _isLoading = false;
      });
    }
  }

  Future<void> _markEverythingRead() async {
    // A broadcast is one row shared by every student, so the server cannot
    // record this student having read it — asking would change nothing.
    if (_messages.every((message) => message.isRead || message.isBroadcast)) {
      return;
    }

    try {
      final unread = await _api.markNotificationsRead();
      await NotificationService.updateBadgeCount(unread);
    } on ApiException {
      // The list is what matters, and it is already on screen.
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
      onTap: message.opensOrder ? () => _open(message) : null,
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

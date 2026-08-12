import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/service/notification_service.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';

class NotificationScreen extends StatefulWidget {
  final dynamic userId;

  const NotificationScreen({super.key, this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const String _baseUrl = ApiConfig.baseUrl;
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingRead = false;

  String? get _userIdString {
    if (widget.userId == null) return null;
    final str = widget.userId.toString().trim();
    return str.isNotEmpty ? str : null;
  }

  @override
  void initState() {
    super.initState();
    NotificationService.removeBadge();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final queryParams = <String, String>{};
    final uid = _userIdString;
    if (uid != null) {
      queryParams['user_id'] = uid;
    }

    final url = Uri.parse('$_baseUrl/get_notifications.php').replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          setState(() {
            _notifications = (data['notifications'] as List?) ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingRead || _notifications.isEmpty) return;

    setState(() => _isMarkingRead = true);

    final queryParams = <String, String>{};
    final uid = _userIdString;
    if (uid != null) {
      queryParams['user_id'] = uid;
    }

    final url = Uri.parse('$_baseUrl/mark_notifications_read.php').replace(queryParameters: queryParams);

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          for (var item in _notifications) {
            if (item is Map) {
              item['is_read'] = 1;
            }
          }
          _isMarkingRead = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Failed to mark notifications as read: $e');
    }

    if (!mounted) return;
    setState(() => _isMarkingRead = false);
  }

  Future<void> _markSingleAsRead(int notificationId, int index) async {
    if (notificationId <= 0) return;
    if ((_notifications[index]['is_read'] ?? 0) == 1 || (_notifications[index]['is_read']?.toString() == '1')) return;

    setState(() {
      _notifications[index]['is_read'] = 1;
    });

    try {
      final queryParams = <String, String>{
        'notification_id': notificationId.toString(),
      };
      final uid = _userIdString;
      if (uid != null) {
        queryParams['user_id'] = uid;
      }

      final url = Uri.parse('$_baseUrl/mark_notifications_read.php')
          .replace(queryParameters: queryParams);
      await http.post(url);
    } catch (e) {
      debugPrint('Failed to mark single notification as read: $e');
    }
  }

  void _showNotificationDetailModal(Map<String, dynamic> item, int index) {
    final notificationId = int.tryParse(item['id']?.toString() ?? '') ?? 0;
    if (notificationId > 0) {
      _markSingleAsRead(notificationId, index);
    }

    final title = item['title']?.toString() ?? '';
    final body = item['body']?.toString() ?? '';
    final type = item['type']?.toString() ?? 'info';
    final createdAt = item['created_at']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getColorForType(type).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(type),
                      color: _getColorForType(type),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: fontHeadTitle,
                            fontWeight: FontWeight.bold,
                            color: TitleColor,
                            fontFamily: getFontFamily(context),
                          ),
                        ),
                        if (createdAt.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            createdAt,
                            style: TextStyle(
                              fontSize: fontText,
                              color: TextSoftColor,
                              fontFamily: getFontFamily(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: StrokeCardColor),
              ),
              Text(
                body,
                style: TextStyle(
                  fontSize: fontSubtitle,
                  height: 1.5,
                  color: TextColor,
                  fontFamily: getFontFamily(context),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ButtonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.bold,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'new_product':
        return Icons.auto_stories_rounded;
      case 'order_update':
      case 'order_completed':
        return Icons.local_shipping_rounded;
      case 'payment_success':
        return Icons.check_circle_rounded;
      case 'news_alert':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'new_product':
        return Colors.purple;
      case 'payment_success':
        return Colors.green;
      case 'order_update':
      case 'order_completed':
        return ButtonColor;
      case 'news_alert':
        return Colors.blue;
      default:
        return IconOrangeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final hasUnread = _notifications.any((n) => (n['is_read'] ?? 0) == 0 || (n['is_read']?.toString() == '0'));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.translate('notifications'),
          style: const TextStyle(fontFamily: 'KhmerMool1', fontSize: fontAppBar, color: TitleColor),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: IconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty && hasUnread)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: lang.translate('mark_all_as_read'),
                icon: _isMarkingRead
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: GText1),
                      )
                    : const Icon(Icons.done_all_rounded, color: GText1, size: 22),
                onPressed: _markAllAsRead,
              ),
            ),
        ],
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
              ? const Center(
                  child: CircularProgressIndicator(color: GText1),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Text(
                        lang.translate('no_notifications'),
                        style: TextStyle(
                          fontSize: fontSubtitle,
                          color: TextSoftColor,
                          fontFamily: getFontFamily(context),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final title = item['title']?.toString() ?? '';
                          final body = item['body']?.toString() ?? '';
                          final createdAt = item['created_at']?.toString() ?? '';
                          final isUnread = (item['is_read'] ?? 0) == 0 || (item['is_read']?.toString() == '0');

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showNotificationDetailModal(Map<String, dynamic>.from(item), index),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUnread ? Colors.white : Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isUnread ? GText1.withOpacity(0.4) : StrokeCardColor,
                                  width: isUnread ? 1.4 : 1.0,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: (isUnread ? Colors.orange : Colors.blue).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isUnread ? Icons.mark_email_unread_rounded : Icons.notifications_rounded,
                                      color: isUnread ? Colors.orange : Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: fontSubtitle,
                                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                  color: TitleColor,
                                                  fontFamily: getFontFamily(context),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          body,
                                          style: TextStyle(
                                            fontSize: fontText,
                                            color: TextColor,
                                            fontFamily: getFontFamily(context),
                                          ),
                                        ),
                                        if (createdAt.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            createdAt,
                                            style: TextStyle(
                                              fontSize: fontText,
                                              color: TextSoftColor,
                                              fontFamily: getFontFamily(context),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

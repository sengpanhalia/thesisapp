import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/service/notification_service.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';

class NotificationScreen extends StatefulWidget {
  final int? userId;

  const NotificationScreen({super.key, this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const String _baseUrl = ApiConfig.baseUrl;
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingRead = false;

  @override
  void initState() {
    super.initState();
    NotificationService.removeBadge();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final queryParams = <String, String>{};
    if ((widget.userId ?? 0) > 0) {
      queryParams['user_id'] = widget.userId.toString();
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
    if ((widget.userId ?? 0) > 0) {
      queryParams['user_id'] = widget.userId.toString();
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
          style: const TextStyle(fontFamily: 'KhmerMool1', fontSize: 22, color: TitleColor),
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
                          fontSize: 14,
                          color: TextSoftColor,
                          fontFamily: getFontFamily(context),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(MgPd20),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final title = item['title']?.toString() ?? '';
                          final body = item['body']?.toString() ?? '';
                          final type = item['type']?.toString() ?? 'info';
                          final createdAt = item['created_at']?.toString() ?? '';
                          final isUnread = (item['is_read'] ?? 0) == 0 || (item['is_read']?.toString() == '0');

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : Colors.white.withValues(alpha: 0.70),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnread ? ButtonColor.withValues(alpha: 0.5) : StrokeCardColor,
                                width: isUnread ? 2 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getColorForType(type).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconForType(type),
                                    color: _getColorForType(type),
                                    size: 22,
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
                                                fontSize: 15,
                                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                color: TitleColor,
                                                fontFamily: getFontFamily(context),
                                              ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: TextColor,
                                          fontFamily: getFontFamily(context),
                                        ),
                                      ),
                                      if (createdAt.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          createdAt,
                                          style: TextStyle(
                                            fontSize: 11,
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
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

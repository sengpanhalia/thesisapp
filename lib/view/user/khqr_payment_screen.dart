import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/khqr_payment_screen.dart';
import 'package:thesisapp/view/main_screen.dart';
import 'package:thesisapp/view/user/checkout_payment.dart';
import 'package:thesisapp/view/user/order_success.dart';

class KhqrPaymentScreen extends StatefulWidget {
  final int? orderId;
  final int? paymentId;
  final List<int> cartIds;
  final List<Map<String, dynamic>> items;
  final double total;
  final DateTime createdAt;

  KhqrPaymentScreen({
    super.key,
    this.orderId,
    this.paymentId,
    this.cartIds = const [],
    required this.items,
    required this.total,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen> {
  static const Duration _khqrExpiry = Duration(minutes: 3);
  static const String _logoAssetPath = 'assets/app_logo.png';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isChecking = false;
  bool _isCancelling = false;
  bool _wasCancelled = false;
  String? _errorMessage;
  String _paymentStatus = 'pending';
  Uint8List? _qrBytes;
  Timer? _autoCheckTimer;
  Timer? _expiryTimer;
  DateTime? _expiresAt;
  Duration _timeRemaining = Duration.zero;
  bool _notifiedPaid = false;
  bool _notifiedExpired = false;
  int? _paymentId;
  int? _orderId;
  String? _trackingNumber;
  final ScreenshotController _qrScreenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    KhqrPaymentWatcher.stop();
    _paymentId = widget.paymentId;
    _orderId = widget.orderId;
    _loadKhqr();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _syncKhqrWatcherForExit();
    _autoCheckTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_isPaid ||
          _isExpired ||
          _isChecking ||
          _isLoading ||
          _errorMessage != null) {
        return;
      }
      _checkPayment(silent: true);
    });
  }

  DateTime? _parseServerDate(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    final normalized = value.contains('T')
        ? value
        : value.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  String? _normalizeTrackingNumber(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }
    return value;
  }

  void _syncKhqrWatcherForExit() {
    final isFailed = _paymentStatus.toLowerCase() == 'failed';
    if (!_isPaid && !_isExpired && !_wasCancelled && !isFailed) {
      KhqrPaymentWatcher.start(
        paymentId: _paymentId,
        orderId: _orderId,
        items: widget.items,
        cartIds: widget.cartIds,
        total: widget.total,
        createdAt: widget.createdAt,
      );
      return;
    }
    KhqrPaymentWatcher.stop();
  }

  Future<void> _refreshCartData() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.fetchCart();
  }

  Future<void> _continueShopping() async {
    if (!mounted) return;
    _syncKhqrWatcherForExit();
    await _refreshCartData();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    if (_expiresAt == null || _isPaid || _isExpired) {
      return;
    }
    _updateRemaining();
    if (_timeRemaining <= Duration.zero) {
      _markExpired(syncServer: true);
      return;
    }
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isPaid || _isExpired) {
        timer.cancel();
        return;
      }
      _updateRemaining();
      if (_timeRemaining <= Duration.zero) {
        timer.cancel();
        _markExpired(syncServer: true);
      }
    });
  }

  void _updateRemaining() {
    if (!mounted || _expiresAt == null) return;
    final diff = _expiresAt!.difference(DateTime.now());
    setState(() {
      _timeRemaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  void _markExpired({bool notify = true, bool syncServer = false}) {
    if (_isPaid) return;
    final alreadyExpired = _paymentStatus.toLowerCase() == 'expired';
    _autoCheckTimer?.cancel();
    _expiryTimer?.cancel();
    if (!alreadyExpired) {
      if (mounted) {
        setState(() {
          _paymentStatus = 'expired';
          _qrBytes = null;
          _timeRemaining = Duration.zero;
        });
      } else {
        _paymentStatus = 'expired';
        _qrBytes = null;
        _timeRemaining = Duration.zero;
      }
    }
    if (notify && !_notifiedExpired) {
      _notifiedExpired = true;
      _showExpiredDialog();
    }
    if (syncServer && mounted) {
      _checkPayment(silent: true);
    }
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('QR Expired'),
          content: const Text(
            'This KHQR code expired after 3 minutes. '
            'Please generate a new QR code to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToCardScreen();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelPayment() async {
    if (_isCancelling || _isPaid) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      Fluttertoast.showToast(msg: 'Please login first');
      return;
    }

    setState(() => _isCancelling = true);
    try {
      final payload = <String, dynamic>{
        'user_id': user.student_id,
        'reason': 'User cancelled payment',
      };
      if (_paymentId != null && _paymentId != 0) {
        payload['payment_id'] = _paymentId;
      }
      if (_orderId != null && _orderId != 0) {
        payload['order_id'] = _orderId;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cancel_khqr_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _autoCheckTimer?.cancel();
          _expiryTimer?.cancel();
          _wasCancelled = true;
          _paymentId = null;
          _orderId = null;
          KhqrPaymentWatcher.stop();
          if (mounted) {
            setState(() {
              _paymentStatus = 'failed';
              _qrBytes = null;
              _expiresAt = null;
              _timeRemaining = Duration.zero;
            });
          }
          Fluttertoast.showToast(msg: 'Payment cancelled');
          await _goToCartScreen();
          return;
        }
        Fluttertoast.showToast(
          msg: data['message'] ?? 'Failed to cancel payment',
        );
      } else {
        Fluttertoast.showToast(msg: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Network error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _goToCartScreen() async {
    if (!mounted) return;
    _syncKhqrWatcherForExit();
    await _refreshCartData();
    if (!mounted) return;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.setIndex(2);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  Future<void> _redirectToCardScreen() async {
    if (!mounted) return;
    _syncKhqrWatcherForExit();
    await _refreshCartData();
    if (!mounted) return;
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => CheckoutPayment(
    //       addressId: widget.address.id,
    //       selectedAddress: widget.address,
    //     ),
    //   ),
    //   (route) => false,
    // );
  }

  String _formatRemaining(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _loadKhqr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _notifiedExpired = false;
      _expiresAt = null;
      _timeRemaining = Duration.zero;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please login first';
      });
      return;
    }

    try {
      if ((widget.orderId == null || widget.orderId == 0) &&
          widget.cartIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Missing cart items for card payment';
        });
        return;
      }

      final payload = <String, dynamic>{
        'user_id': user.student_id,
        'amount': widget.total,
      };
      if (widget.orderId != null && widget.orderId != 0) {
        payload['order_id'] = widget.orderId;
      } else {
        // payload['address_id'] = widget.address.id;
        payload['cart_ids'] = widget.cartIds;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/create_khqr.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final payload = data['data'] is Map
              ? Map<String, dynamic>.from(data['data'])
              : (data['qr_base64'] != null
                    ? Map<String, dynamic>.from(data)
                    : <String, dynamic>{});
          final base64Raw = (payload['qr_base64'] ?? payload['qrBase64'] ?? '')
              .toString();
          if (base64Raw.isNotEmpty) {
            final cleaned = base64Raw.contains(',')
                ? base64Raw.split(',').last
                : base64Raw;
            try {
              _qrBytes = base64Decode(cleaned);
            } catch (_) {
              _qrBytes = null;
            }
          }
          final rawStatus =
              (payload['payment_status'] ?? payload['status'])?.toString() ??
              'pending';
          _paymentStatus = rawStatus;
          final expiresRaw = payload['expires_at'];
          final createdRaw = payload['created_at'];
          final createdAt = _parseServerDate(createdRaw);
          final expiresAt =
              _parseServerDate(expiresRaw) ??
              (createdAt != null ? createdAt.add(_khqrExpiry) : null);
          _expiresAt = expiresAt;
          final paymentIdRaw = payload['id'] ?? payload['payment_id'];
          final orderIdRaw = payload['order_id'];
          final trackingNumber = _normalizeTrackingNumber(
            payload['tracking_number'] ?? payload['trackingNumber'],
          );
          _paymentId = int.tryParse(paymentIdRaw?.toString() ?? '');
          _orderId = int.tryParse(orderIdRaw?.toString() ?? '');
          if (trackingNumber != null) {
            _trackingNumber = trackingNumber;
          }
          if (_expiresAt != null &&
              DateTime.now().isAfter(_expiresAt!) &&
              !_isPaid) {
            _paymentStatus = 'expired';
            _qrBytes = null;
          }
        } else {
          _errorMessage = data['message'] ?? 'Failed to generate KHQR';
        }
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (_isExpired) {
          _markExpired();
        } else {
          _startExpiryTimer();
        }
      }
    }
  }

  Future<void> _checkPayment({bool silent = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final idParam = _paymentId != null
          ? 'payment_id=$_paymentId'
          : (_orderId != null ? 'order_id=$_orderId' : '');
      if (idParam.isEmpty) {
        if (!silent) {
          Fluttertoast.showToast(msg: 'Missing payment reference');
        }
        if (mounted) {
          setState(() => _isChecking = false);
        }
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/check_khqr_payment.php?$idParam'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final rawStatus =
              (data['payment_status'] ?? data['status_value'] ?? '')
                  .toString()
                  .trim();
          final expiresRaw = data['expires_at'];
          if (expiresRaw != null) {
            final parsed = _parseServerDate(expiresRaw);
            if (parsed != null) {
              _expiresAt = parsed;
              if (!_isExpired && !_isPaid) {
                _startExpiryTimer();
              }
            }
          }
          final nowExpired =
              _expiresAt != null &&
              DateTime.now().isAfter(_expiresAt!) &&
              !_isPaid;
          if (nowExpired) {
            _markExpired(notify: !silent, syncServer: false);
            return;
          }
          if (rawStatus.isNotEmpty) {
            if (rawStatus.toLowerCase() == 'expired') {
              _markExpired(notify: !silent, syncServer: false);
              return;
            }
            setState(() => _paymentStatus = rawStatus);
          }
          final orderIdRaw = data['order_id'];
          final parsedOrderId = int.tryParse(orderIdRaw?.toString() ?? '');
          if (parsedOrderId != null && parsedOrderId > 0) {
            _orderId = parsedOrderId;
          }
          final trackingNumber = _normalizeTrackingNumber(
            data['tracking_number'] ?? data['trackingNumber'],
          );
          if (trackingNumber != null) {
            _trackingNumber = trackingNumber;
          }
          if (_isPaid) {
            if (!_notifiedPaid) {
              Fluttertoast.showToast(msg: 'Payment confirmed');
              _notifiedPaid = true;
            }
            _autoCheckTimer?.cancel();
          } else if (!silent) {
            Fluttertoast.showToast(msg: 'Payment still pending');
          }
        } else {
          if (!silent) {
            Fluttertoast.showToast(
              msg: data['message'] ?? 'Failed to check payment',
            );
          }
        }
      } else {
        if (!silent) {
          Fluttertoast.showToast(msg: 'Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (!silent) {
        Fluttertoast.showToast(msg: 'Network error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  bool get _isPaid {
    final v = _paymentStatus.toLowerCase();
    return v == 'paid' || v == 'success' || v == 'completed';
  }

  bool get _isExpired {
    return _paymentStatus.toLowerCase() == 'expired';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'completed':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'expired':
        return 'Expired';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'completed':
        return const Color(0xFF2D6A4F);
      case 'failed':
      case 'expired':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    if (Platform.isAndroid) {
      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;
      final photos = await Permission.photos.request();
      return photos.isGranted || photos.isLimited;
    }
    if (Platform.isIOS) {
      final addOnly = await Permission.photosAddOnly.request();
      if (addOnly.isGranted || addOnly.isLimited) return true;
      final photos = await Permission.photos.request();
      return photos.isGranted || photos.isLimited;
    }
    return true;
  }

  Future<void> _saveQrImage() async {
    if (_isSaving || _qrBytes == null) return;
    setState(() => _isSaving = true);
    try {
      final allowed = await _ensureGalleryPermission();
      if (!allowed) {
        Fluttertoast.showToast(msg: 'Permission denied');
        return;
      }
      final bytes = await _captureQrCardImage();
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'khqr_${_orderId ?? _paymentId ?? 'payment'}',
      );
      final isSuccess = result is Map
          ? (result['isSuccess'] == true || result['success'] == true)
          : result == true;
      Fluttertoast.showToast(
        msg: isSuccess ? 'Saved to gallery' : 'Save failed',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save image: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<Uint8List> _captureQrCardImage() async {
    final refLabel = _orderId != null && _orderId != 0
        ? 'Order #$_orderId'
        : (_paymentId != null ? 'Payment #$_paymentId' : 'Payment Pending');
    final card = _buildQrCardForSave(refLabel);

    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final bytes = await _qrScreenshotController.captureFromWidget(
      MediaQuery(
        data: media.copyWith(
          padding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: Theme(
          data: theme,
          child: Material(
            color: const Color(0xFFF7F3EE),
            child: Center(child: card),
          ),
        ),
      ),
      pixelRatio: 2.5,
    );

    if (bytes == null) {
      throw Exception('Failed to capture QR card');
    }
    return bytes;
  }

  Widget _buildQrCardForSave(String refLabel) {
    return SizedBox(
      width: 360,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _logoAssetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KHQR Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        refLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${widget.total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildQrWithLogo(size: 220),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan to pay',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Valid for 3 minutes',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  void _openReceipt() {
    if (_orderId == null || _orderId == 0) {
      Fluttertoast.showToast(msg: 'Order not created yet');
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: _orderId ?? 0,
          // address: widget.address,
          items: widget.items,
          total: widget.total,
          paymentMethod: 'card',
          createdAt: widget.createdAt,
          trackingNumber: _trackingNumber,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final refLabel = _orderId != null && _orderId != 0
        ? 'Order #$_orderId'
        : (_paymentId != null ? 'Payment #$_paymentId' : 'Payment Pending');
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Colors.grey[600];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, primary),
              Text(
                'Scan the KHQR code to complete payment',
                style: GoogleFonts.poppins(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Payment Summary',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      refLabel,
                      style: GoogleFonts.poppins(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${widget.total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              _paymentStatus,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(_paymentStatus),
                            style: GoogleFonts.poppins(
                              color: _statusColor(_paymentStatus),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_expiresAt != null && !_isPaid)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _isExpired
                              ? 'QR expired'
                              : 'Expires in ${_formatRemaining(_timeRemaining)}',
                          style: GoogleFonts.poppins(
                            color: _isExpired
                                ? Colors.redAccent
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'KHQR Code',
                child: Column(
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _loadKhqr,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_isExpired)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            const Text(
                              'QR code expired. Please generate a new QR code.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _loadKhqr,
                              child: const Text('Generate New QR'),
                            ),
                          ],
                        ),
                      )
                    else if (_qrBytes == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('QR not available'),
                      )
                    else
                      _buildQrWithLogo(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _qrBytes == null || _isSaving
                            ? null
                            : _saveQrImage,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save QR to Gallery',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // SizedBox(
              //   width: double.infinity,
              //   child: OutlinedButton.icon(
              //     onPressed: _isChecking || _isExpired
              //         ? null
              //         : () => _checkPayment(),
              //     icon: _isChecking
              //         ? const SizedBox(
              //             width: 18,
              //             height: 18,
              //             child: CircularProgressIndicator(strokeWidth: 2),
              //           )
              //         : const Icon(Icons.refresh_rounded),
              //     // label: Text(
              //     //   _isChecking ? 'Checking...' : 'Check Payment Status',
              //     // ),
              //     style: OutlinedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 14),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       side: BorderSide(color: primary),
              //     ),
              //   ),
              // ),
              if (!_isPaid) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isCancelling ? null : _cancelPayment,
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded),
                    label: Text(
                      _isCancelling ? 'Cancelling...' : 'Cancel Payment',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPaid && (_orderId != null && _orderId != 0)
                      ? _openReceipt
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Receipt'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _continueShopping,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: primary),
                  ),
                  child: const Text('Continue Shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: RoundIconButton(
            //     icon: Icons.arrow_back_rounded,
            //     iconColor: primary,
            //     onPressed: () => Navigator.pop(context),
            //   ),
            // ),
            Center(
              child: Text(
                'KHQR Payment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrWithLogo({double size = 240}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.memory(
            _qrBytes!,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          Container(
            height: size * 0.23,
            width: size * 0.23,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                _logoAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.store_rounded, color: Colors.black45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

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
              (createdAt?.add(_khqrExpiry));
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
            _expiryTimer?.cancel();
            // Clear the ordered cart items and re-fetch cart
            final cartProvider = context.read<CartProvider>();
            if (widget.cartIds.isNotEmpty) {
              cartProvider.removeCheckedOutItems(widget.cartIds);
            }
            await cartProvider.fetchCart();
            // Navigate to order success screen
            if (mounted) {
              _openReceipt();
            }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildAmountCard(),
              const SizedBox(height: 16),
              _buildQrCard(),
              const SizedBox(height: 20),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Converts a USD dollar amount to KHR (approximate rate 4100 riel per USD)
  String _toKhrDisplay(double usd) {
    final riel = (usd * 4100).round();
    // Format with space separators like "៣២ ០០០"
    final formatted = riel.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    // Convert ASCII digits to Khmer digits
    const khmerDigits = ['០','១','២','៣','៤','៥','៦','៧','៨','៩'];
    return formatted.split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? khmerDigits[d] : c;
    }).join();
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ការទូទាត់សរុប',
            style: TextStyle(
              fontFamily: 'KhmerMool1',
              fontSize: 15,
              color: Color(0xFF5E574F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\u17DB ${_toKhrDisplay(widget.total)}',
            style: const TextStyle(
              fontFamily: 'KhmerMool1',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2822),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          if (_expiresAt != null && !_isPaid)
            Text(
              _isExpired
                  ? 'ផុតកំណត់ : ០០ នាទី'
                  : 'ដល់ : ${_formatRemaining(_timeRemaining)} នាទី',
              style: const TextStyle(
                fontFamily: 'KhmerMool1',
                fontSize: 13,
                color: Color(0xFFCC0000),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_expiresAt != null && !_isPaid) const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'ចំណាំ ៖ ',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 12,
                    color: Color(0xFFCC0000),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: 'KHQR Code',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFCC0000),
                  ),
                ),
                const TextSpan(
                  text: ' នឹងផុតកំណត់ក្នុងរយៈពេល ៣ នាទី',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 12,
                    color: Color(0xFFCC0000),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(color: Color(0xFFD97F2E)),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 52),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadKhqr,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97F2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ព្យាយាមម្ដងទៀត'),
                  ),
                ],
              ),
            )
          else if (_isExpired)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.timer_off_rounded, color: Colors.redAccent, size: 52),
                  const SizedBox(height: 12),
                  const Text(
                    'KHQR Code ផុតកំណត់',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'KhmerMool1',
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'សូមបង្កើត QR Code ថ្មី',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'KhmerMool1',
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadKhqr,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97F2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'បង្កើត QR Code ថ្មី',
                      style: TextStyle(fontFamily: 'KhmerMool1'),
                    ),
                  ),
                ],
              ),
            )
          else if (_qrBytes == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Text(
                'QR មិនមាន',
                style: TextStyle(fontFamily: 'KhmerMool1', color: Colors.grey, fontSize: 14),
              ),
            )
          else
            _buildQrWithLogo(size: 240),
          if (!_isLoading && _qrBytes != null && !_isExpired) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _saveQrImage,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97F2E)),
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  _isSaving ? 'កំពុងរក្សាទុក...' : 'រក្សាទុករូបភាព',
                  style: const TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97F2E),
                  side: const BorderSide(color: Color(0xFFD97F2E), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        if (_isPaid) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_orderId != null && _orderId != 0) ? _openReceipt : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D8C4E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'View Receipt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!_isPaid) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCancelling ? null : _cancelPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isCancelling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'បោះបង់ការទូទាត់',
                      style: TextStyle(
                        fontFamily: 'KhmerMool1',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _continueShopping,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97F2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text(
              'ត្រឡប់ក្រោយ',
              style: TextStyle(
                fontFamily: 'KhmerMool1',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'ទូទាត់តាមរយៈ ',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2C2822),
                  ),
                ),
                TextSpan(
                  text: 'KHQR Code',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C2822),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'សូមចូចស្កែន KHQR Code សម្រាប់ធ្វើការទូទាត់',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'KhmerMool1',
              fontSize: 13,
              color: Color(0xFF3A3530),
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'ចំណាំ ៖ ',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 12,
                    color: Color(0xFFCC0000),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text: 'រូបិយបណ្ណសម្រាប់ប្រើប្រាស់ក្នុងការបង់ប្រាក់គឺ រៀល (៛)',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 12,
                    color: Color(0xFFCC0000),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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



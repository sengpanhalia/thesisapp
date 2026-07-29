import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/order_success.dart';

class Address {
  final int id;
  final String label;

  const Address({required this.id, required this.label});
}

class KhqrPaymentWatcher {
  static bool isActive = false;
  static int? paymentId;
  static int? orderId;
  static Address? address;
  static List<Map<String, dynamic>> items = [];
  static List<int> cartIds = [];
  static double? total;
  static DateTime? createdAt;

  static bool get hasPayload => items.isNotEmpty && total != null;

  static void start({
    int? paymentId,
    int? orderId,
    // required Address address,
    required List<Map<String, dynamic>> items,
    required List<int> cartIds,
    required double total,
    required DateTime createdAt,
  }) {
    KhqrPaymentWatcher.isActive = true;
    KhqrPaymentWatcher.paymentId = paymentId;
    KhqrPaymentWatcher.orderId = orderId;
    KhqrPaymentWatcher.address = address;
    KhqrPaymentWatcher.items = List<Map<String, dynamic>>.from(items);
    KhqrPaymentWatcher.cartIds = List<int>.from(cartIds);
    KhqrPaymentWatcher.total = total;
    KhqrPaymentWatcher.createdAt = createdAt;
  }

  static void stop() {
    isActive = false;
    paymentId = null;
    orderId = null;
    address = null;
    items = [];
    cartIds = [];
    total = null;
    createdAt = null;
  }
}

class KhqrPaymentScreen extends StatefulWidget {
  final int? orderId;
  final int? paymentId;
  final List<int> cartIds;
  // final Address address;
  final List<Map<String, dynamic>> items;
  final double total;
  final DateTime createdAt;

  KhqrPaymentScreen({
    super.key,
    this.orderId,
    this.paymentId,
    this.cartIds = const [],
    // required this.address,
    required this.items,
    required this.total,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen> {
  static const Duration _khqrExpiry = Duration(minutes: 3);

  bool _isLoading = true;
  bool _isChecking = false;
  bool _isSaving = false;
  bool _isCancelling = false;
  String _paymentStatus = 'pending';
  String? _errorMessage;
  Uint8List? _qrBytes;
  int? _paymentId;
  int? _orderId;
  Timer? _checkTimer;
  final ScreenshotController _screenshotController = ScreenshotController();
  Timer? _expiryTimer;
  DateTime? _expiresAt;
  Duration _timeRemaining = Duration.zero;
  bool _notifiedExpired = false;

  @override
  void initState() {
    super.initState();
    _paymentId = widget.paymentId;
    _orderId = widget.orderId;
    KhqrPaymentWatcher.start(
      paymentId: widget.paymentId,
      orderId: widget.orderId,
      items: widget.items,
      cartIds: widget.cartIds,
      total: widget.total,
      createdAt: widget.createdAt,
    );
    _loadKhqr();
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isPaid && !_isChecking && !_isExpired) {
        _checkPayment(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  bool get _isPaid {
    final status = _paymentStatus.toLowerCase();
    return status == 'paid' || status == 'success' || status == 'completed';
  }

  bool get _isExpired => _paymentStatus.toLowerCase() == 'expired';

  // ---- Save QR ----

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
      final bytes = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: Material(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildQrWithLogo(size: 260),
            ),
          ),
        ),
        pixelRatio: 3.0,
      );
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'khqr_${_orderId ?? _paymentId ?? 'payment'}',
      );
      final isSuccess = result is Map
          ? (result['isSuccess'] == true || result['success'] == true)
          : result == true;
      Fluttertoast.showToast(
        msg: isSuccess ? 'រូបភាពបានរក្សាទុក' : 'បរាជ័យក្នុងការរក្សាទុក',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---- Cancel Payment ----

  Future<void> _cancelPayment() async {
    if (_isCancelling || _isPaid) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('បោះបង់ការទូទាត់', style: TextStyle(fontFamily: 'KhmerMool1')),
        content: const Text('តើអ្នកប្រាកដថាចង់បោះបង់ការទូទាត់?', style: TextStyle(fontFamily: 'KhmerMool1')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ទេ', style: TextStyle(fontFamily: 'KhmerMool1')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('បាទ/ចាស', style: TextStyle(fontFamily: 'KhmerMool1', color: RedColor)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isCancelling = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) {
        Fluttertoast.showToast(msg: 'Please login first');
        return;
      }
      final payload = <String, dynamic>{
        'user_id': user.student_id,
        'reason': 'User cancelled payment',
      };
      if (_paymentId != null) payload['payment_id'] = _paymentId;
      if (_orderId != null) payload['order_id'] = _orderId;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cancel_khqr_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _checkTimer?.cancel();
          _expiryTimer?.cancel();
          KhqrPaymentWatcher.stop();
          Fluttertoast.showToast(msg: 'បានបោះបង់ការទូទាត់');
          await _finish();
          return;
        }
        Fluttertoast.showToast(msg: data['message'] ?? 'Failed to cancel');
      } else {
        Fluttertoast.showToast(msg: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  // ---- KHR helpers ----

  /// Converts USD to KHR Khmer-digit string like "៛ ៣២ ០០០"
  String _toKhrDisplay(double usd) {
    final riel = (usd * 4100).round();
    final formatted = riel.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    const khmerDigits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
    return formatted.split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? khmerDigits[d] : c;
    }).join();
  }

  String _formatRemaining(Duration d) {
    final m = (d.inSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---- Expiry ----

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    if (_expiresAt == null || _isPaid || _isExpired) return;
    _updateRemaining();
    if (_timeRemaining <= Duration.zero) {
      _markExpired();
      return;
    }
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_isPaid || _isExpired) { t.cancel(); return; }
      _updateRemaining();
      if (_timeRemaining <= Duration.zero) {
        t.cancel();
        _markExpired();
      }
    });
  }

  void _updateRemaining() {
    if (!mounted || _expiresAt == null) return;
    final diff = _expiresAt!.difference(DateTime.now());
    setState(() => _timeRemaining = diff.isNegative ? Duration.zero : diff);
  }

  void _markExpired() {
    if (_isPaid) return;
    _expiryTimer?.cancel();
    _checkTimer?.cancel();
    if (mounted) {
      setState(() {
        _paymentStatus = 'expired';
        _qrBytes = null;
        _timeRemaining = Duration.zero;
      });
    }
    if (!_notifiedExpired) {
      _notifiedExpired = true;
      _showExpiredDialog();
    }
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'KHQR Code ផុតកំណត់',
          style: TextStyle(fontFamily: 'KhmerMool1'),
        ),
        content: const Text(
          'KHQR Code ផុតកំណត់ក្រោយ ៣ នាទី។ សូមបង្កើត QR Code ថ្មីដើម្បីបន្ត។',
          style: TextStyle(fontFamily: 'KhmerMool1'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadKhqr();
            },
            child: const Text(
              'បង្កើតថ្មី',
              style: TextStyle(fontFamily: 'KhmerMool1', color: ButtonColor),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Network ----

  Future<void> _loadKhqr() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() { _isLoading = false; _errorMessage = 'Please login first'; });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _notifiedExpired = false;
      _expiresAt = null;
      _timeRemaining = Duration.zero;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/create_khqr.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.student_id,
          'student_id': user.student_id,
          'amount': widget.total,
          'cart_ids': widget.cartIds,
          if (widget.orderId != null) 'order_id': widget.orderId,
        }),
      );

      if (response.statusCode != 200) {
        _errorMessage = 'Server error: ${response.statusCode}';
        return;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['status'] != 'success') {
        _errorMessage = data is Map
            ? (data['message']?.toString() ?? 'Failed to generate KHQR')
            : 'Failed to generate KHQR';
        return;
      }

      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'])
          : data;
      final qrBase64 = (payload['qr_base64'] ?? payload['qrBase64'] ?? '').toString();
      if (qrBase64.isNotEmpty) {
        final cleaned = qrBase64.contains(',') ? qrBase64.split(',').last : qrBase64;
        _qrBytes = base64Decode(cleaned);
      }

      _paymentStatus =
          (payload['payment_status'] ?? payload['status_value'] ?? 'pending').toString();
      _paymentId = int.tryParse((payload['payment_id'] ?? payload['id'] ?? '').toString());
      _orderId = int.tryParse((payload['order_id'] ?? '').toString());

      // Parse expiry
      final expiresRaw = payload['expires_at'] ?? payload['created_at'];
      if (expiresRaw != null) {
        final raw = expiresRaw.toString().trim();
        final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
        final parsed = DateTime.tryParse(normalized);
        _expiresAt = parsed?.add(
          payload['expires_at'] != null ? Duration.zero : _khqrExpiry,
        );
      }
      _expiresAt ??= DateTime.now().add(_khqrExpiry);

      if (!_isPaid && _expiresAt!.isBefore(DateTime.now())) {
        _paymentStatus = 'expired';
        _qrBytes = null;
      }

      KhqrPaymentWatcher.start(
        paymentId: _paymentId,
        orderId: _orderId,
        items: widget.items,
        cartIds: widget.cartIds,
        total: widget.total,
        createdAt: widget.createdAt,
      );
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
    final idParam = _paymentId != null
        ? 'payment_id=$_paymentId'
        : (_orderId != null ? 'order_id=$_orderId' : '');
    if (idParam.isEmpty) {
      if (!silent) Fluttertoast.showToast(msg: 'Missing payment reference');
      return;
    }

    setState(() => _isChecking = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/check_khqr_payment.php?$idParam'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final nextStatus =
              (data['payment_status'] ?? data['status_value'] ?? _paymentStatus).toString();
          setState(() => _paymentStatus = nextStatus);
          if (_isPaid) {
            KhqrPaymentWatcher.stop();
            _expiryTimer?.cancel();
            _checkTimer?.cancel();
            // Clear the ordered cart items then re-fetch to sync with server
            final cartProvider = context.read<CartProvider>();
            if (widget.cartIds.isNotEmpty) {
              cartProvider.removeCheckedOutItems(widget.cartIds);
            }
            await cartProvider.fetchCart();
            if (mounted) setState(() {});
            return;
          } else if (_isExpired) {
            _markExpired();
          } else if (!silent) {
            Fluttertoast.showToast(msg: 'Payment still pending');
          }
        } else if (!silent) {
          Fluttertoast.showToast(msg: data['message'] ?? 'Check failed');
        }
      } else if (!silent) {
        Fluttertoast.showToast(msg: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!silent) Fluttertoast.showToast(msg: 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _finish() async {
    final cartProvider = context.read<CartProvider>();
    if (_isPaid) {
      KhqrPaymentWatcher.stop();
      // Clear ordered cart items before navigating away
      if (widget.cartIds.isNotEmpty) {
        cartProvider.removeCheckedOutItems(widget.cartIds);
      }
    }
    await cartProvider.fetchCart();
    if (!mounted) return;
    context.read<NavigationProvider>().setIndex(_isPaid ? 0 : 2);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: _orderId ?? widget.orderId ?? 0,
          items: widget.items,
          total: widget.total,
          paymentMethod: 'KHQR Payment',
          createdAt: widget.createdAt,
        ),
      ),
      (route) => false,
    );
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    // Show full success screen when paid
    if (_isPaid) {
      return Scaffold(
        backgroundColor: GBackground1,
        body: SafeArea(child: _buildSuccessScreen()),
      );
    }

    return Scaffold(
      backgroundColor: GBackground1,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
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

  Widget _buildSuccessScreen() {
    final lang = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          // Animated success icon
          Lottie.asset(
            'assets/Done.json',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            repeat: true,
            animate: true,
          ),
          // Container(
          //   width: 120,
          //   height: 120,
          //   decoration: BoxDecoration(
          //     color: GreenColor.withOpacity(0.12),
          //     shape: BoxShape.circle,
          //   ),
          //   child: Container(
          //     margin: const EdgeInsets.all(16),
          //     decoration: const BoxDecoration(
          //       color: GreenColor,
          //       shape: BoxShape.circle,
          //     ),
          //     child: const Icon(
          //       Icons.check_rounded,
          //       color: Colors.white,
          //       size: 52,
          //     ),
          //   ),
          // ),
          const SizedBox(height: 5),
          Text(
            lang.translate('payment Successful!'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: getFontFamilyMool1(context),
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: TitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.translate('thank you for your payment!'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: 14,
              color: TextColor,
            ),
          ),
          const SizedBox(height: 32),
          // Amount summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.translate('amount'),
                      style: TextStyle(
                        fontFamily: getFontFamily(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TextColor,
                      ),
                    ),
                    Text(
                      '\$${widget.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: getFontFamily(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: GreenColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: StrokeSearchBar),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.translate('status'),
                      style: TextStyle(
                        fontFamily: getFontFamily(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TextColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: GreenColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        lang.translate('paid'),
                        style: TextStyle(
                          fontFamily: getFontFamily(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: GreenColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: GreenColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: Text(
                lang.translate('done'),
                style: TextStyle(
                  fontFamily: getFontFamily(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title: "ទូទាត់តាមរយៈ" + bold "KHQR Code"
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
                    color: TitleColor,
                  ),
                ),
                TextSpan(
                  text: 'KHQR Code',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Subtitle
          const Text(
            'សូមចូចស្កែន KHQR Code សម្រាប់ធ្វើការទូទាត់',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'KhmerMool1',
              fontSize: 13,
              color: TextColor,
            ),
          ),
          const SizedBox(height: 4),
          // Red currency note
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'ចំណាំ ៖ ',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 12,
                    color: RedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: 'រូបិយបណ្ណសម្រាប់ប្រើប្រាស់ក្នុងការបង់ប្រាក់គឺ រៀល (៛)',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 12,
                    color: RedColor,
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
              color: TextColor,
            ),
          ),
          const SizedBox(height: 6),
          // Large KHR amount in Khmer digits
          Text(
            '៛ ${_toKhrDisplay(widget.total)}',
            style: const TextStyle(
              fontFamily: 'KhmerMool1',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: TitleColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          // Red timer
          if (_expiresAt != null && !_isPaid)
            Text(
              _isExpired
                  ? 'ផុតកំណត់ : ០០ នាទី'
                  : 'ដល់ : ${_formatRemaining(_timeRemaining)} នាទី',
              style: const TextStyle(
                fontFamily: 'KhmerMool1',
                fontSize: 13,
                color: RedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_expiresAt != null && !_isPaid) const SizedBox(height: 6),
          // Red expiry note
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'ចំណាំ ៖ ',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 12,
                    color: RedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: 'KHQR Code',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: RedColor,
                  ),
                ),
                const TextSpan(
                  text: ' នឹងផុតកំណត់ក្នុងរយៈពេល ៣ នាទី',
                  style: TextStyle(
                    fontFamily: 'KhmerMool1',
                    fontSize: 12,
                    color: RedColor,
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
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: ButtonColor)),
            )
          : _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: RedColor, size: 52),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: RedColor, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadKhqr,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ButtonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'ព្យាយាមម្ដងទៀត',
                          style: TextStyle(fontFamily: 'KhmerMool1'),
                        ),
                      ),
                    ],
                  ),
                )
              : _isExpired
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const Icon(Icons.timer_off_rounded, color: RedColor, size: 52),
                          const SizedBox(height: 12),
                          const Text(
                            'KHQR Code ផុតកំណត់',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'KhmerMool1',
                              color: RedColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'សូមបង្កើត QR Code ថ្មី',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'KhmerMool1', color: TextColor, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadKhqr,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ButtonColor,
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
                  : _qrBytes == null
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Text(
                            'QR មិនមាន',
                            style: TextStyle(fontFamily: 'KhmerMool1', color: TextColor),
                          ),
                        )
                      : Column(
                          children: [
                            _buildQrWithLogo(size: 240),
                            const SizedBox(height: 20),
                            // Green Save QR button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveQrImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GreenColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: GreenColor.withOpacity(0.6),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'រក្សាទុក QR',
                                        style: TextStyle(
                                          fontFamily: 'KhmerMool1',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
            height: size * 0.22,
            width: size * 0.22,
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
                'assets/app_logo.png',
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

  Widget _buildBottomButtons() {
    return Column(
      children: [
        // Red Cancel Payment button (shown when not paid)
        if (!_isPaid)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCancelling ? null : _cancelPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: RedColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: RedColor.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
        if (!_isPaid) const SizedBox(height: 10),

        // Orange Back / Done button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: ButtonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            child: Text(
              _isPaid ? 'រួចរាល់' : 'ត្រឡប់ក្រោយ',
              style: const TextStyle(
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
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: RedColor),
        ),
        const SizedBox(height: Height10),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

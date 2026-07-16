import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/main_screen.dart';

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

  static bool get hasPayload =>
      address != null && items.isNotEmpty && total != null;

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
  bool _isLoading = true;
  bool _isChecking = false;
  String _paymentStatus = 'pending';
  String? _errorMessage;
  Uint8List? _qrBytes;
  int? _paymentId;
  int? _orderId;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _paymentId = widget.paymentId;
    _orderId = widget.orderId;
    KhqrPaymentWatcher.start(
      paymentId: widget.paymentId,
      orderId: widget.orderId,
      // address: widget.address,
      items: widget.items,
      cartIds: widget.cartIds,
      total: widget.total,
      createdAt: widget.createdAt,
    );
    _loadKhqr();
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isPaid && !_isChecking) {
        _checkPayment(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  bool get _isPaid {
    final status = _paymentStatus.toLowerCase();
    return status == 'paid' || status == 'success' || status == 'completed';
  }

  Future<void> _loadKhqr() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please login first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
          // if (widget.address.id > 0) 'address_id': widget.address.id,
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
      final qrBase64 = (payload['qr_base64'] ?? payload['qrBase64'] ?? '')
          .toString();
      if (qrBase64.isNotEmpty) {
        final cleaned = qrBase64.contains(',')
            ? qrBase64.split(',').last
            : qrBase64;
        _qrBytes = base64Decode(cleaned);
      }

      _paymentStatus =
          (payload['payment_status'] ?? payload['status_value'] ?? 'pending')
              .toString();
      _paymentId = int.tryParse(
        (payload['payment_id'] ?? payload['id'] ?? '').toString(),
      );
      _orderId = int.tryParse((payload['order_id'] ?? '').toString());
      KhqrPaymentWatcher.start(
        paymentId: _paymentId,
        orderId: _orderId,
        // address: widget.address,
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
              (data['payment_status'] ?? data['status_value'] ?? _paymentStatus)
                  .toString();
          setState(() => _paymentStatus = nextStatus);
          if (_isPaid) {
            KhqrPaymentWatcher.stop();
            await context.read<CartProvider>().fetchCart();
            if (!silent) Fluttertoast.showToast(msg: 'Payment confirmed');
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
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _finish() async {
    if (_isPaid) {
      KhqrPaymentWatcher.stop();
    }
    await context.read<CartProvider>().fetchCart();
    if (!mounted) return;
    context.read<NavigationProvider>().setIndex(_isPaid ? 0 : 2);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  Color _statusColor() {
    if (_isPaid) return GreenColor;
    if (_paymentStatus.toLowerCase() == 'failed') return RedColor;
    return ButtonColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GBackground1,
      appBar: AppBar(
        title: const Text(
          'KHQR Payment',
          style: TextStyle(fontFamily: UEFontFamily),
        ),
        backgroundColor: GBackground1,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MgPd20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(MgPd20),
                decoration: BoxDecoration(
                  color: CardColor,
                  borderRadius: BorderRadius.circular(Round20),
                  border: Border.all(color: StrokeSearchBar),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontFamily: UEFontFamily,
                        color: TextColor,
                      ),
                    ),
                    Text(
                      '\$${widget.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: UEFontFamily,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: GText1,
                      ),
                    ),
                    const SizedBox(height: Height10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor().withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _isPaid ? 'Paid' : _paymentStatus,
                        style: TextStyle(
                          color: _statusColor(),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Height20),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : _errorMessage != null
                      ? _ErrorState(message: _errorMessage!, onRetry: _loadKhqr)
                      : _qrBytes == null
                      ? const Text('QR code is not available')
                      : Image.memory(_qrBytes!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: Height20),
              ElevatedButton.icon(
                onPressed: _isChecking ? null : () => _checkPayment(),
                icon: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(_isChecking ? 'Checking...' : 'Check payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ButtonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: Height10),
              OutlinedButton(
                onPressed: _finish,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_isPaid ? 'Done' : 'Back to cart'),
              ),
            ],
          ),
        ),
      ),
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

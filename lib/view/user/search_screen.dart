import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/product.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String baseUrl;

  const SearchScreen({super.key, required this.baseUrl});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Color _accent = Color(0xFFD67C2A);
  static const String _historyKey = 'recent_searches';

  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  NavigationProvider? _navigationProvider;

  List<String> _history = [];
  List<Product> _products = [];

  bool _isLoadingHistory = true;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _loadHistory();
    _fetchProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NavigationProvider>();
    if (_navigationProvider == provider) return;

    _navigationProvider?.removeListener(_syncFocusWithTab);
    _navigationProvider = provider..addListener(_syncFocusWithTab);

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFocusWithTab());
  }

  @override
  void dispose() {
    _navigationProvider?.removeListener(_syncFocusWithTab);
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncFocusWithTab() {
    if (!mounted) return;
    final isSearchTab = _navigationProvider?.currentIndex == 1;
    if (isSearchTab) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? const [];
      if (!mounted) return;
      setState(() {
        _history = list.where((e) => e.trim().isNotEmpty).toList();
        _isLoadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveHistory(List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, value);
  }

  Future<void> _addToHistory(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;

    final lower = value.toLowerCase();
    final next = <String>[
      value,
      ..._history.where((e) => e.trim().toLowerCase() != lower),
    ];

    final capped = next.length > 10 ? next.take(10).toList() : next;
    if (!mounted) return;
    setState(() => _history = capped);
    await _saveHistory(capped);
  }

  Future<void> _removeHistoryItem(String value) async {
    final lower = value.trim().toLowerCase();
    final next = _history
        .where((e) => e.trim().toLowerCase() != lower)
        .toList();
    if (!mounted) return;
    setState(() => _history = next);
    await _saveHistory(next);
  }

  Future<void> _clearHistory() async {
    if (!mounted) return;
    setState(() => _history = []);
    await _saveHistory([]);
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    final url = Uri.parse('${widget.baseUrl}/get_products.php');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode != 200) {
        Fluttertoast.showToast(msg: 'Server error: ${response.statusCode}');
        setState(() => _isLoadingProducts = false);
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['status'] == 'success') {
        final list = (decoded['products'] as List?) ?? const [];
        setState(() {
          _products = list
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList();
          _isLoadingProducts = false;
        });
        return;
      }

      Fluttertoast.showToast(msg: 'Failed to load products');
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Network error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  List<Product> _results() {
    final q = _queryController.text.trim().toLowerCase();
    if (q.isEmpty) return const [];

    return _products.where((p) {
      final name = p.name.toLowerCase();
      final desc = p.description.toLowerCase();
      final author = p.author.toLowerCase();
      final category = p.category.toLowerCase();
      return name.contains(q) ||
          desc.contains(q) ||
          author.contains(q) ||
          category.contains(q);
    }).toList();
  }

  void _openProduct(Product product) {
    _addToHistory(_queryController.text);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(product: product, baseUrl: widget.baseUrl),
      ),
    );
  }

  // Widget _background() {
  //   return Stack(
  //     children: [
  //       BackgroundColor(),
  //       Positioned.fill(
  //         child: IgnorePointer(
  //           child: CustomPaint(
  //             painter: _VerticalStripesPainter(
  //               color: const Color(0xFFEADBCB).withOpacity(0.35),
  //               stripeWidth: 14,
  //               gapWidth: 18,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _searchBar() {
    final lang = AppLocalizations.of(context)!;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _queryController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _addToHistory(value),
              decoration: InputDecoration(
                fillColor: Colors.transparent,
                hintText: lang.translate('search'),
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: TextSoftColor,
                  // fontWeight: FontWeight.w500,
                  fontFamily: UKFontFamily,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Container(
          //   height: 36,
          //   width: 36,
          //   decoration: BoxDecoration(
          //     color: _accent.withOpacity(0.12),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: const Icon(Icons.tune_rounded, color: _accent, size: 20),
          // ),
        ],
      ),
    );
  }

  Widget _historyHeader(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          lang.translate('history'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: UKFontFamily,
          ),
        ),
        IconButton(
          onPressed: _history.isEmpty ? null : _clearHistory,
          icon: const Icon(Icons.delete_outline_rounded, color: _accent),
          tooltip: 'Clear',
        ),
      ],
    );
  }

  Widget _historyList(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return Center(
        child: Text(
          lang.translate('no_data_found'),
          style: const TextStyle(
            color: TextColor,
            fontFamily: UKFontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final term = _history[index];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _queryController.text = term;
            _queryController.selection = TextSelection.collapsed(
              offset: _queryController.text.length,
            );
            _addToHistory(term);
          },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.66),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.55)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: Colors.black45,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    term,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeHistoryItem(term),
                  child: Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resultsList(List<Product> results) {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No results',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = results[index];
        final imageUrl = '${widget.baseUrl}/uploads/products/${product.image}';
        final price = double.tryParse(product.price) ?? 0.0;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openProduct(product),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.55)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 48,
                    width: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 48,
                      width: 48,
                      color: const Color(0xFFF3F0EA),
                      child: const Center(
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 48,
                      width: 48,
                      color: const Color(0xFFF3F0EA),
                      child: const Icon(Icons.broken_image_rounded, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.author.trim().isEmpty
                            ? (product.category.trim().isEmpty
                                  ? 'Book'
                                  : product.category.trim())
                            : product.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "\$${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim();
  final lang = AppLocalizations.of(context)!;

    final results = _results();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Text(
          lang.translate('search'),
          style: TextStyle(fontFamily: 'KhmerMool1', fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // BackgroundColor(),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              // Matching the warm gradient from your design
              gradient: gradientColor(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchBar(),
                    const SizedBox(height: 14),
                    if (query.isEmpty) _historyHeader(context),
                    if (query.isEmpty) const SizedBox(height: 6),
                    Expanded(
                      child: query.isEmpty
                          ? _historyList(context)
                          : _resultsList(results),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class _VerticalStripesPainter extends CustomPainter {
//   final Color color;
//   final double stripeWidth;
//   final double gapWidth;

//   const _VerticalStripesPainter({
//     required this.color,
//     required this.stripeWidth,
//     required this.gapWidth,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = color;
//     final step = stripeWidth + gapWidth;
//     for (double x = 0; x < size.width; x += step) {
//       canvas.drawRect(Rect.fromLTWH(x, 0, stripeWidth, size.height), paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _VerticalStripesPainter oldDelegate) {
//     return oldDelegate.color != color ||
//         oldDelegate.stripeWidth != stripeWidth ||
//         oldDelegate.gapWidth != gapWidth;
//   }
// }

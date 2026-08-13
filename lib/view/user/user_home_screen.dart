import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/carousel_slider.dart';
import 'package:thesisapp/component/category_section_widget.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/recommended_products_section.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/product.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/user_api.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/notification_screen.dart';
import 'package:thesisapp/view/user/product_detail_screen.dart';
import 'package:thesisapp/view/user/product_screen.dart';
import 'package:thesisapp/view/user/search_screen.dart';

// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  static const String _baseUrl = ApiConfig.baseUrl;
  final TextEditingController searchController = TextEditingController();

  /// All products from the API, grouped by DB category (lowercase key).
  Map<String, List<Product>> _productsByCategory = {};
  List<Product> _randomProducts = [];
  UserDetail? _userDetail;
  bool _isLoadingProducts = true;
  int _unreadNotificationCount = 0;

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
    });
    await Future.wait([
      _fetchProducts(),
      _fetchUserData(),
      _fetchUnreadNotificationCount(),
    ]);
  }

  // ------------------------------------------------------------------
  String getGreeting() {
    final lang = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return '${lang.translate('good morning')},';
    if (hour < 17) return '${lang.translate('good afternoon')},';
    if (hour < 20) return '${lang.translate('good evening')},';
    return '${lang.translate('good night')},';
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(baseUrl: _baseUrl)),
    );
  }

  // ------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchUserData();
    _fetchUnreadNotificationCount();
  }

  Future<void> _fetchUnreadNotificationCount() async {
    final authUser = context.read<AuthProvider>().user;
    final studentId = (authUser?.student_id.isNotEmpty == true)
        ? authUser!.student_id
        : _userDetail?.student_id;

    final queryParams = <String, String>{};
    if (studentId != null && studentId.trim().isNotEmpty) {
      queryParams['user_id'] = studentId.trim();
    }

    final url = Uri.parse('$_baseUrl/get_notifications.php').replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final List list = (data['notifications'] as List?) ?? [];
          final unread = list.where((item) => (item['is_read'] ?? 0) == 0 || (item['is_read']?.toString() == '0')).length;
          setState(() {
            _unreadNotificationCount = unread;
          });
        }
      }
    } catch (_) {}
  }

  /// Fetch all products in one request then group by category.
  Future<void> _fetchProducts() async {
    final url = Uri.parse('$_baseUrl/get_products.php');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final List productsJson = (data['products'] as List?) ?? const [];
          final allProducts = productsJson
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList();

          // Group products by normalised category name
          final grouped = <String, List<Product>>{};
          for (final p in allProducts) {
            final key = p.category.trim().toLowerCase();
            grouped.putIfAbsent(key, () => []).add(p);
          }

          // Pick 10 random products once during fetch so UI remains stable
          final randomList = List<Product>.from(allProducts)..shuffle(Random());
          final randomTen = randomList.take(10).toList();

          setState(() {
            _productsByCategory = grouped;
            _randomProducts = randomTen;
            _isLoadingProducts = false;
          });
          return;
        }
      }
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    setState(() => _isLoadingProducts = false);
  }

  Future<void> _fetchUserData() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) {
      if (!mounted) return;
      return;
    }

    try {
      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse(APILocalLoginUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "student_id": authUser.student_id,
                "pwd": authUser.pwd,
              }),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        response = await http.post(
          Uri.parse(APIStLoginKh),
          body: {'student_id': authUser.student_id, 'pwd': authUser.pwd},
        );
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final userData =
              (decoded['user_data'] as List?) ??
              (decoded['student_users'] as List?) ??
              (decoded['user'] != null ? [decoded['user']] : const []);
          final details = userData
              .whereType<Map<String, dynamic>>()
              .map(UserDetail.fromJson)
              .toList();

          final detail = details.isNotEmpty ? details.first : null;
          if (!mounted) return;
          setState(() {
            _userDetail = detail;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load user detail: $e');
    }

    if (!mounted) return;
  }

  // ------------------------------------------------------------------
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        leadingWidth: MediaQuery.of(context).size.width,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: MgPd20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getGreeting(),
                    style: TextStyle(
                      fontSize: fontSubtitle,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  SizedBox(height: Height5),
                  textGradient(
                    'សាកលវិទ្យាល័យ​ សៅស៍អុីសថ៍អេយសៀ',
                    TextStyle(
                      fontSize: fontSubtitle,
                      color: Colors.white,
                      fontFamily: 'KhmerMool1',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MgPd20),
            child: GestureDetector(
              onTap: () async {
                final authUser = context.read<AuthProvider>().user;
                final studentId = (authUser?.student_id.isNotEmpty == true)
                    ? authUser!.student_id
                    : _userDetail?.student_id;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationScreen(
                      userId: studentId,
                    ),
                  ),
                );
                _fetchUnreadNotificationCount();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(color: StrokeSearchBar, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: TextColor,
                      size: 22,
                    ),
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MgPd20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search bar ──────────────────────────────────────────
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: StrokeSearchBar, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Colors.black45),
                        const SizedBox(width: Width5),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            readOnly: true,
                            onTap: _openSearch,
                            decoration: InputDecoration(
                              fillColor: Colors.transparent,
                              hintText: '${lang.translate('search')}...',
                              hintStyle: TextStyle(
                                fontSize: fontText,
                                color: TextSoftColor,
                                fontFamily: getFontFamily(context),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: Height15),

                  // ── Carousel banner ─────────────────────────────────────
                  CarouselSliderWidget(
                    images: [
                      'assets/slide1.png',
                      'assets/slide2.png',
                      'assets/slide3.png',
                    ],
                  ),

                  SizedBox(height: Height15),

                  // ── Category sections ───────────────────────────────────
                  if (_isLoadingProducts)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: GText1),
                      ),
                    )
                  else
                    ..._buildCategorySections(context),

                  SizedBox(height: Height20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  /// Builds one section widget per category that has at least one product.
  List<Widget> _buildCategorySections(BuildContext context) {
    final sections = <Widget>[];
    final lang = AppLocalizations.of(context)!;
    final isEnglish = lang.locale.languageCode == 'en';

    // Iterate over every category key that came back from the API
    for (final entry in _productsByCategory.entries) {
      if (entry.key.trim().isEmpty) continue;
      final products = entry.value;
      if (products.isEmpty) continue;

      // Use category info from the first product in the list
      final firstProduct = products.first;
      final categoryName = firstProduct.category;
      final categoryNameKh = firstProduct.categoryKh;
      final categoryId = firstProduct.categoryId; // FK

      final categoryTitle = isEnglish
          ? (categoryName.isNotEmpty ? categoryName : categoryNameKh)
          : (categoryNameKh.isNotEmpty ? categoryNameKh : categoryName);

      sections.add(CategorySectionWidget(
        title: categoryTitle,
        products: products,
        baseUrl: _baseUrl,
        onSeeAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductScreen(
                categoryId: categoryId,
                categoryName: categoryName,
                categoryTitle: categoryTitle,
              ),
            ),
          );
        },
        onProductTap: (product) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                baseUrl: _baseUrl,
              ),
            ),
          );
        },
      ));

      sections.add(SizedBox(height: Height15));
    }

    if (sections.isEmpty) {
      sections.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              lang.translate('no items found'),
              style: TextStyle(
                fontSize: fontSubtitle,
                color: TextSoftColor,
                fontFamily: getFontFamily(context),
              ),
            ),
          ),
        ),
      );
    }

    // ── Random products from all categories (always shown at the bottom) ──
    if (_randomProducts.isNotEmpty) {
      sections.add(SizedBox(height: Height5));
      sections.add(RecommendedProductsSection(
        title: lang.translate('general product'),
        products: _randomProducts,
        baseUrl: _baseUrl,
        onSeeAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductScreen()),
          );
        },
        onProductTap: (product) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                baseUrl: _baseUrl,
              ),
            ),
          );
        },
      ));
    }

    return sections;
  }
}

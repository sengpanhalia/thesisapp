import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/card_product.dart';
import 'package:thesisapp/component/carousel_slider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/model/product.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/user_api.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/product_detail_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _baseUrl = ApiConfig.baseUrl;
  final TextEditingController searchController = TextEditingController();

  List<Product> _products = [];
  UserDetail? _userDetail;
  bool _isLoadingProducts = true;
  bool _isLoadingUser = true;

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'អរុណសួស្តី,'; // Good Morning in Khmer
    } else if (hour < 17) {
      return 'ទិវាសួស្តី,'; // Good Afternoon in Khmer
    } else if (hour < 20) {
      return 'សាយន្តសួស្តី,'; // Afternoon in Khmer
    } else {
      return 'រាត្រីសួស្តី,'; // Evening in Khmer
    }
  }

  void _openSearch() {
    context.read<NavigationProvider>().setIndex(1);
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchUserData();
  }

  Future<void> _fetchProducts() async {
    final url = Uri.parse('$_baseUrl/get_products.php');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final List productsJson = (data['products'] as List?) ?? const [];
          setState(() {
            _products = productsJson
                .whereType<Map<String, dynamic>>()
                .map(Product.fromJson)
                .toList();
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
      setState(() => _isLoadingUser = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(APIStLoginKh),
        body: {'student_id': authUser.student_id, 'pwd': authUser.pwd},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final userData =
              (decoded['user_data'] as List?) ??
              (decoded['student_users'] as List?) ??
              const [];
          final details = userData
              .whereType<Map<String, dynamic>>()
              .map(UserDetail.fromJson)
              .toList();

          if (!mounted) return;
          setState(() {
            _userDetail = details.isNotEmpty ? details.first : null;
            _isLoadingUser = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load user detail: $e');
    }

    if (!mounted) return;
    setState(() => _isLoadingUser = false);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canShowProducts = !_isLoadingProducts;
    final profileImageUrl = (_userDetail?.profile_pic ?? '').trim();
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
                      fontSize: 14,
                      color: TextColor,
                      fontFamily: UKFontFamily,
                    ),
                  ),
                  SizedBox(height: Height5),
                  textGradient(
                    'សាកលវិទ្យាល័យ​ សៅស៍អុីសថ៍អេយសៀ',
                    TextStyle(
                      fontSize: 15,
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
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.95),
                backgroundImage: profileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(profileImageUrl)
                    : null,
                child: _isLoadingUser
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : profileImageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.black45)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Matching the warm gradient from your design
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
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           getGreeting(),
                  //           style: TextStyle(
                  //             fontSize: 14,
                  //             color: TextColor,
                  //             fontFamily: UKFontFamily,
                  //           ),
                  //         ),
                  //         SizedBox(height: Height5),
                  //         textGradient(
                  //           'សាកលវិទ្យាល័យ​ សៅស៍អុីសថ៍អេយសៀ',
                  //           TextStyle(
                  //             fontSize: 15,
                  //             color: Colors.white,
                  //             fontFamily: 'KhmerMool1',
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //     CircleAvatar(
                  //       radius: 22,
                  //       backgroundColor: Colors.white,
                  //       child: CircleAvatar(
                  //         radius: 30,
                  //         backgroundImage: AssetImage('assets/image.JPG'),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(height: Height15),
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
                              hintText: 'ស្វែងរក...',
                              // hintStyle: GoogleFonts.poppins(
                              //   fontSize: 13,
                              //   color: Colors.black45,
                              //   fontWeight: FontWeight.w500,
                              // ),
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: TextSoftColor,
                                // fontWeight: FontWeight.w500,
                                fontFamily: UKFontFamily,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Height15),
                  CarouselSliderWidget(
                    images: [
                      'assets/slide1.png',
                      'assets/slide2.png',
                      'assets/slide3.png',
                    ],
                  ),
                  SizedBox(height: Height15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'សៀវភៅប្រចាំឆមាស',
                        style: TextStyle(
                          fontSize: 16,
                          color: TextColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: UKFontFamily,
                        ),
                      ),
                      GestureDetector(
                        child: Text(
                          'មើលទាំងអស់',
                          style: TextStyle(
                            fontSize: 13,
                            color: GText1,
                            fontFamily: UKFontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Height10),
                  if (!canShowProducts)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  if (canShowProducts && _products.isEmpty)
                    Text(
                      'មិនមានសៀវភៅទេ',
                      style: TextStyle(
                        fontSize: 14,
                        color: TextSoftColor,
                        fontFamily: UKFontFamily,
                      ),
                    ),
                  if (canShowProducts && _products.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final productImage = (product.image ?? '').trim();
                        final imageUrl = productImage.startsWith('http')
                            ? productImage
                            : '$_baseUrl/uploads/products/$productImage';

                        return BuildCardProduct(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: product,
                                  baseUrl: _baseUrl,
                                ),
                              ),
                            );
                          },
                          productName: product.name,
                          productPrice: product.price,
                          imageUrl: imageUrl,
                          productImage: productImage,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

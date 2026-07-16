import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:thesisapp/component/card_product.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/product.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/product_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  final String? categoryName;
  final String? categoryTitle;

  const ProductScreen({super.key, this.categoryName, this.categoryTitle});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const Map<String, Set<String>> _categoryAliases = {
    'books': {'books', 'book'},
    't-shirts': {'t-shirts', 't-shirt', 'tshirts', 'tshirt'},
    'materials': {'materials', 'material'},
  };

  List<Product> product = [];
  bool _isLoadingProduct = true;

  Set<String> get _selectedCategoryValues {
    final selectedValues = <String>{};

    for (final value in [widget.categoryName, widget.categoryTitle]) {
      final normalizedValue = _normalizeCategory(value ?? '');
      if (normalizedValue.isEmpty) continue;

      selectedValues.add(normalizedValue);
      selectedValues.addAll(
        _categoryAliases[normalizedValue] ?? const <String>{},
      );
    }

    return selectedValues;
  }

  static String _normalizeCategory(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_]+'), '-');
  }

  bool _matchesSelectedCategory(Product product) {
    final selectedValues = _selectedCategoryValues;
    if (selectedValues.isEmpty) return true;

    return selectedValues.contains(_normalizeCategory(product.category));
  }

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    _fetchProducts();
  }

  // Future<void> _fetchProducts() async {
  //   final url = Uri.parse('$_baseUrl/get_products.php');
  //   try {
  //     final response = await http.get(url);
  //     if (!mounted) return;

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data is Map<String, dynamic> && data['status'] == 'success') {
  //         final List productsJson = (data['products'] as List?) ?? const [];
  //         setState(() {
  //           _products = productsJson
  //               .whereType<Map<String, dynamic>>()
  //               .map(Product.fromJson)
  //               .toList();
  //           _isLoadingProducts = false;
  //         });
  //         return;
  //       }
  //     }
  //   } catch (_) {
  //     // ignore
  //   }

  //   if (!mounted) return;
  //   setState(() => _isLoadingProducts = false);
  // }

  Future<void> _fetchProducts() async {
    final url = Uri.parse("$_baseUrl/get_products.php");
    try {
      final response = await http.get(url);
      if (!mounted) {
        return;
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final List productsJson = (data['products'] as List?) ?? const [];
          setState(() {
            product = productsJson
                .whereType<Map<String, dynamic>>()
                .map(Product.fromJson)
                .where(_matchesSelectedCategory)
                .toList();
            _isLoadingProduct = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load products: $e');
    }

    if (!mounted) return;
    setState(() {
      _isLoadingProduct = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canShowProducts = !_isLoadingProduct;
    final categoryTitle = (widget.categoryTitle ?? '').trim();
    final categoryName = (widget.categoryName ?? '').trim();
    final screenTitle = categoryTitle.isNotEmpty
        ? categoryTitle
        : categoryName.isNotEmpty
        ? AppLocalizations.of(context)!.translate(categoryName)
        : AppLocalizations.of(context)!.translate('books');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Text(
          screenTitle,
          style: const TextStyle(fontFamily: 'KhmerMool1', fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      // body: GridView.builder(
      //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      //     crossAxisCount: 2,
      //                       mainAxisSpacing: 12,
      //                       crossAxisSpacing: 12,
      //                       childAspectRatio: 0.65,
      //   ),
      //   itemBuilder: (context, index){
      //     return
      //   },
      // ),
      body: Container(
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
            padding: const EdgeInsets.symmetric(
              horizontal: MgPd20,
              vertical: MgPd10,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (!canShowProducts)
                    Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  if (canShowProducts && product.isEmpty)
                    Text(
                      'មិនមានសៀវភៅទេ',
                      style: TextStyle(
                        fontSize: 14,
                        color: TextSoftColor,
                        fontFamily: getFontFamily(context),
                      ),
                    ),
                  if (canShowProducts && product.isNotEmpty)
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
                      itemCount: product.length,
                      itemBuilder: (context, index) {
                        final products = product[index];
                        final productImage = (products.image ?? '').trim();
                        final imageUrl = productImage.startsWith('http')
                            ? productImage
                            : '$_baseUrl/uploads/products/$productImage';

                        return BuildCardProduct(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: products,
                                  baseUrl: _baseUrl,
                                ),
                              ),
                            );
                          },
                          productName: products.name,
                          productPrice: products.price,
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

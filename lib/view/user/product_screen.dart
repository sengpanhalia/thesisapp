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
  final int?    categoryId;    // FK: categories.id — preferred filter
  final String? categoryName;  // fallback filter by name
  final String? categoryTitle; // display title in AppBar
  final List<Product>? initialProducts;

  const ProductScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.categoryTitle,
    this.initialProducts,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const int _limit = 10;

  List<Product> product = [];
  bool _isLoadingProduct = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isFetching = false; // Synchronous guard against duplicate calls
  int _offset = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (widget.initialProducts != null && widget.initialProducts!.isNotEmpty) {
      product = List<Product>.from(widget.initialProducts!);
      _isLoadingProduct = false;
      _offset = product.length;
      _hasMore = product.length >= _limit;
    } else {
      _fetchProducts(isInitial: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isFetching || !_hasMore || _isLoadingProduct || _isLoadingMore) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 200) {
      _fetchProducts(isInitial: false);
    }
  }

  Future<void> _fetchProducts({required bool isInitial}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (isInitial) {
      setState(() {
        _isLoadingProduct = true;
        _offset = 0;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final catId   = widget.categoryId ?? 0;
    final catName = (widget.categoryName ?? '').trim();

    final queryParams = <String, String>{
      'limit': _limit.toString(),
      'offset': _offset.toString(),
    };

    if (catId > 0) {
      queryParams['category_id'] = catId.toString();
    } else if (catName.isNotEmpty) {
      queryParams['category'] = catName;
    }

    final uri = (catId > 0 || catName.isNotEmpty)
        ? Uri.parse('$_baseUrl/get_products_by_category.php').replace(queryParameters: queryParams)
        : Uri.parse('$_baseUrl/get_products.php').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      if (!mounted) {
        _isFetching = false;
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final List productsJson = (data['products'] as List?) ?? const [];
          final newProducts = productsJson
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList();

          if (!mounted) {
            _isFetching = false;
            return;
          }

          setState(() {
            if (isInitial) {
              product = newProducts;
            } else {
              // Deduplicate: only add products that are not already in the list
              final existingIds = product.map((p) => p.id).toSet();
              final uniqueNew = newProducts.where((p) => !existingIds.contains(p.id)).toList();
              product.addAll(uniqueNew);
            }

            _offset += newProducts.length;
            _hasMore = newProducts.length >= _limit;
            _isLoadingProduct = false;
            _isLoadingMore = false;
          });

          _isFetching = false;
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load products: $e');
    }

    if (!mounted) {
      _isFetching = false;
      return;
    }

    setState(() {
      _isLoadingProduct = false;
      _isLoadingMore = false;
      _hasMore = false;
    });
    _isFetching = false;
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
          style: TextStyle(fontFamily: 'KhmerMool1', fontSize: fontAppBar),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MgPd20,
              vertical: MgPd10,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  if (_isLoadingProduct)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  if (canShowProducts && product.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'មិនមានសៀវភៅទេ',
                          style: TextStyle(
                            fontSize: fontSubtitle,
                            color: TextSoftColor,
                            fontFamily: getFontFamily(context),
                          ),
                        ),
                      ),
                    ),
                  if (canShowProducts && product.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: product.length,
                      itemBuilder: (context, index) {
                        final products = product[index];
                        final productImage = (products.image ?? '').trim();
                        final imageUrl = buildProductImageUrl(_baseUrl, productImage);

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
                          author: products.author,
                        );
                      },
                    ),
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

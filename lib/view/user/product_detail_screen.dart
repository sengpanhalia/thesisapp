import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:thesisapp/component/card_product.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/full_image_view.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/component/product_spec_row.dart';
import 'package:thesisapp/component/recommended_products_section.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Book book;

  const ProductDetailScreen({super.key, required this.book});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final InventoryApi _api = InventoryApi();

  /// The book as last read from the server. Availability moves while the
  /// student is reading the page, so the screen re-reads it rather than
  /// trusting the copy the list screen handed over.
  late Book _book = widget.book;

  List<Book> relatedProducts = [];
  List<Book> recommendedProducts = [];
  bool _isLoadingRelatedProducts = true;
  bool _isLoadingRecommendedProducts = true;

  @override
  void initState() {
    super.initState();
    _refreshBook();
    _fetchProductsData();
  }

  Future<void> _refreshBook() async {
    try {
      final fresh = await _api.refreshBook(widget.book);
      if (!mounted || fresh == null) return;

      setState(() => _book = fresh);
    } on ApiException catch (error) {
      debugPrint('Could not refresh the book: $error');
    }
  }

  Future<void> _fetchProductsData() async {
    try {
      final books = await _api.books();
      if (!mounted) return;

      final others = books.where((b) => b.id != widget.book.id).toList();

      // The API gives a book a year level and an author; it has no categories,
      // so "related" means the same year level first, then the same author.
      final currentYear = widget.book.yearLevel.trim().toLowerCase();
      final currentAuthor = widget.book.author.trim().toLowerCase();

      final sameYear = currentYear.isEmpty
          ? <Book>[]
          : others
                .where((b) => b.yearLevel.trim().toLowerCase() == currentYear)
                .toList();

      final sameAuthor = currentAuthor.isEmpty
          ? <Book>[]
          : others
                .where((b) => b.author.trim().toLowerCase() == currentAuthor)
                .toList();

      final related = [
        ...sameYear,
        ...sameAuthor.where((b) => !sameYear.any((item) => item.id == b.id)),
        ...others.where(
          (b) =>
              !sameYear.any((item) => item.id == b.id) &&
              !sameAuthor.any((item) => item.id == b.id),
        ),
      ].take(10).toList();

      final recommended = List<Book>.from(others)..shuffle(Random());

      setState(() {
        relatedProducts = related;
        recommendedProducts = recommended.take(10).toList();
        _isLoadingRelatedProducts = false;
        _isLoadingRecommendedProducts = false;
      });
      return;
    } on ApiException catch (error) {
      debugPrint('Could not load related books: $error');
    }

    if (!mounted) return;
    setState(() {
      relatedProducts = [];
      recommendedProducts = [];
      _isLoadingRelatedProducts = false;
      _isLoadingRecommendedProducts = false;
    });
  }

  /// Puts the book in the basket kept on this phone. Nothing is held at the
  /// counter until checkout sends the reservation.
  Future<bool> _addToCart(BuildContext context, {int quantity = 1}) async {
    final user = context.read<AuthProvider>().user;
    final lang = AppLocalizations.of(context)!;

    if (user == null) {
      Fluttertoast.showToast(msg: lang.translate('please_log_in_first'));
      return false;
    }

    final added = await context.read<CartProvider>().addBook(
      _book,
      quantity: quantity,
    );

    if (!context.mounted) return false;

    if (!added) {
      Fluttertoast.showToast(
        msg: lang.translate('not_enough_stock'),
        backgroundColor: Colors.redAccent,
      );
      return false;
    }

    Fluttertoast.showToast(
      msg: '${lang.translate('added to cart')} (x$quantity)',
      backgroundColor: Colors.green,
    );

    return true;
  }

  Future<void> _buyNow({int quantity = 1}) async {
    final navigationProvider = context.read<NavigationProvider>();
    final added = await _addToCart(context, quantity: quantity);
    if (!added || !mounted) return;
    navigationProvider.setIndex(2);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<int?> _showQuantityDialog(
    BuildContext context, {
    required int maxQuantity,
  }) {
    final lang = AppLocalizations.of(context)!;

    int quantity = 1;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                lang.translate('select quantity'),
                style: TextStyle(
                  fontFamily: getFontFamily(context),
                  fontSize: fontHeadTitle,
                  fontWeight: FontWeight.w600,
                  color: TitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang.translate('how many would you like to add'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.w600,
                      color: TextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   '${lang.translate('available stock')}: ${maxQuantity < 0 ? 0 : maxQuantity}',
                  //   style: TextStyle(
                  //     fontFamily: getFontFamily(context),
                  //     fontSize: fontSubtitle,
                  //     fontWeight: FontWeight.w500,
                  //     color: GreenColor,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setState(() => quantity -= 1)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        color: TextColor,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            fontFamily: getFontFamilyMool1(context),
                            fontSize: fontHeadTitle,
                            fontWeight: FontWeight.w700,
                            color: TitleColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: (maxQuantity > 0 && quantity >= maxQuantity)
                            ? null
                            : () => setState(() => quantity += 1),
                        icon: const Icon(Icons.add_rounded),
                        color: TextColor,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    lang.translate('cancel'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.w600,
                      color: TitleColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, quantity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GText1,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    lang.translate('confirm'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.w600,
                      color: GBackground1,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullImageView(imageUrl: imageUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isKhmer = lang.locale.languageCode == 'km';

    final String author = _book.author.trim();
    final String? imageUrl = buildProductImageUrl(_book.imageUrl);

    // Null means the catalogue does not say how many are free — not that none
    // are. The quantity picker is then unbounded and the server decides.
    final int? availableQty = _book.availableQty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate('product details'),
          style: TextStyle(
            fontFamily: getFontFamily(context),
            fontSize: fontAppBar,
            color: TitleColor,
          ),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                left: MgPd20,
                right: MgPd20,
                top: MgPd20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(MgPd20),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: imageUrl == null
                              ? Container(
                                  color: GBackground1,
                                  child: bookPlaceholder(),
                                )
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: GBackground1,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: GBackground1,
                                        child: bookPlaceholder(),
                                      ),
                                ),
                        ),
                        if (imageUrl != null)
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Material(
                            color: GBackground1,
                            elevation: 6,
                            borderRadius: BorderRadius.circular(MgPd10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(MgPd10),
                              onTap: () => _openFullImage(imageUrl),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 6),
                                    Text(
                                      lang.translate('view image'),
                                      style: TextStyle(
                                        fontFamily: getFontFamily(context),
                                        fontSize: fontText,
                                        color: TextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Height10),
                  Text(
                    _book.titleFor(khmer: isKhmer),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontTitle,
                      fontWeight: FontWeight.bold,
                      color: TitleColor,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: Height5),
                  Text(
                    '${lang.translate('author')}: $author',
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontSubtitle,
                      color: TextColor,
                    ),
                  ),
                  SizedBox(height: Height10),
                  Text(
                    formatMoney(_book.price),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontAppBar,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height5),
                  Text(
                    availableQty == null
                        ? lang.translate('availability_unknown')
                        : availableQty <= 0
                        ? lang.translate('out of stock')
                        : '${lang.translate('in stock')}: $availableQty ${_book.unit}',
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontText,
                      color: (availableQty ?? 1) <= 0 ? RedColor : GreenColor,
                    ),
                  ),
                  // SizedBox(height: Height15),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 10,
                  //     vertical: 6,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: stockColor.withValues(alpha: 0.12),
                  //     borderRadius: BorderRadius.circular(999),
                  //   ),
                  //   child: Text(
                  //     isOutOfStock
                  //         ? lang.translate('out of stock')
                  //         : '${lang.translate('in stock')}: $stockQuantity',
                  //     style: TextStyle(
                  //       fontFamily: getFontFamily(context),
                  //       fontSize: fontText,
                  //       color: stockColor,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: Height15),

                  // What the catalogue holds: code, publisher, ISBN.
                  ProductSpecRow(
                    code: _book.code,
                    publisher: _book.publisher,
                    isbn: _book.isbn,
                    codeLabel: lang.translate('book_code'),
                    publisherLabel: lang.translate('publisher'),
                    isbnLabel: lang.translate('isbn'),
                  ),

                  SizedBox(height: Height20),
                  Text(
                    lang.translate('product details'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.bold,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height10),
                  Container(width: 90, height: 2, color: GText1),
                  SizedBox(height: Height15),
                  // The catalogue keeps no description for a book, so the two
                  // spellings of the title and the year level it is set for
                  // are what there is to say about it.
                  Text(
                    [
                      _book.titleFor(khmer: !isKhmer),
                      if (_book.yearLevel.isNotEmpty) _book.yearLevel,
                    ].join('\n'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontText,
                      color: TextColor,
                      height: LineHegiht,
                      letterSpacing: 0.7,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: Height20),

                  // Related Books Section
                  Text(
                    lang.translate('related books'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.bold,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height10),
                  if (_isLoadingRelatedProducts)
                    const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (relatedProducts.isEmpty)
                    SizedBox(
                      height: 80,
                      child: Center(
                        child: Text(
                          lang.translate('no related books'),
                          style: TextStyle(
                            fontFamily: getFontFamily(context),
                            fontSize: fontSubtitle,
                            color: TextSoftColor,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        itemBuilder: (context, index) {
                          final related = relatedProducts[index];

                          return SizedBox(
                            width: 180,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: BuildCardProduct(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailScreen(book: related),
                                    ),
                                  );
                                },
                                productName: related.titleFor(khmer: isKhmer),
                                priceLabel: formatMoney(related.price),
                                imageUrl: buildProductImageUrl(
                                  related.imageUrl,
                                ),
                                author: related.author,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Recommended Products Section
                  if (!_isLoadingRecommendedProducts && recommendedProducts.isNotEmpty) ...[
                    const SizedBox(height: Height20),
                    RecommendedProductsSection(
                      title: lang.translate('recommended products'),
                      books: recommendedProducts,
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductScreen(),
                          ),
                        );
                      },
                      onBookTap: (book) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(book: book),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(MgPd20, 12, MgPd20, 12),
          decoration: const BoxDecoration(
            color: CardColor,
            border: Border(top: BorderSide(color: StrokeSearchBar)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final quantity = await _showQuantityDialog(
                      context,
                      maxQuantity: availableQty ?? 0,
                    );
                    if (quantity == null) return;
                    await _addToCart(context, quantity: quantity);
                  },
                  child: Text(
                    lang.translate('add to cart'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.w600,
                      color: TitleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final quantity = await _showQuantityDialog(
                      context,
                      maxQuantity: availableQty ?? 0,
                    );
                    if (quantity == null) return;
                    await _buyNow(quantity: quantity);
                  },
                  child: Text(
                    lang.translate('buy now'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontTitle,
                      fontWeight: FontWeight.w600,
                      color: GBackground3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

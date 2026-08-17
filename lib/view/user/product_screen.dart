import 'package:flutter/material.dart';
import 'package:thesisapp/component/card_product.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/product_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  /// A book category id from `GET /categories.php`. When set, the screen shows
  /// that category's books; it takes precedence over [yearLevel].
  final int? categoryId;

  /// `Year 1`…`Year 4`, or null for the whole sellable catalogue. Kept for the
  /// "all books" tile and any caller that still browses by year.
  final String? yearLevel;

  /// Display title in the AppBar.
  final String? categoryTitle;

  /// Books the previous screen already had, shown while the fresh read runs.
  final List<Book>? initialBooks;

  const ProductScreen({
    super.key,
    this.categoryId,
    this.yearLevel,
    this.categoryTitle,
    this.initialBooks,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final InventoryApi _api = InventoryApi();

  List<Book> books = [];
  bool _isLoadingProduct = true;
  String? _loadError;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final initial = widget.initialBooks;

    if (initial != null && initial.isNotEmpty) {
      books = List<Book>.from(initial);
      _isLoadingProduct = false;
    }

    // Availability moves; the list is read again even when one was handed in.
    _fetchBooks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// The API returns the whole set in one response — neither `/books.php` nor
  /// `/categories.php?id=` pages — so this reads it once. A category id routes
  /// to the category listing; otherwise it is the year-level (or whole)
  /// catalogue.
  Future<void> _fetchBooks() async {
    try {
      final categoryId = widget.categoryId;
      final fetched = categoryId != null
          ? await _api.booksInCategory(categoryId)
          : await _api.books(yearLevel: widget.yearLevel);
      if (!mounted) return;

      setState(() {
        books = fetched;
        _loadError = null;
        _isLoadingProduct = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error.message(AppLocalizations.of(context));
        _isLoadingProduct = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final canShowProducts = !_isLoadingProduct;
    final categoryTitle = (widget.categoryTitle ?? '').trim();
    final yearLevel = (widget.yearLevel ?? '').trim();
    final screenTitle = categoryTitle.isNotEmpty
        ? categoryTitle
        : yearLevel.isNotEmpty
        ? yearLevel
        : lang.translate('books');

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
                  if (canShowProducts && books.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          _loadError ?? lang.translate('no_books_available'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSubtitle,
                            color: TextSoftColor,
                            fontFamily: getFontFamily(context),
                          ),
                        ),
                      ),
                    ),
                  if (canShowProducts && books.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];

                        return BuildCardProduct(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(book: book),
                              ),
                            );
                          },
                          productName: book.titleFor(
                            khmer: lang.locale.languageCode == 'km',
                          ),
                          priceLabel: formatMoney(book.price),
                          imageUrl: buildProductImageUrl(book.imageUrl),
                          author: book.author,
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

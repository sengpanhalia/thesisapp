import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/carousel_slider.dart';
import 'package:thesisapp/component/category_section_widget.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/recommended_products_section.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/model/book_category.dart';
import 'package:thesisapp/model/reservation.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/service/student_directory.dart';
import 'package:thesisapp/service/student_session_store.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/notification_screen.dart';
import 'package:thesisapp/view/user/product_detail_screen.dart';
import 'package:thesisapp/view/user/product_screen.dart';
import 'package:thesisapp/view/user/search_screen.dart';

// ---------------------------------------------------------------------------

/// A home-screen section: one category and the books a student may buy from it.
class _HomeCategory {
  const _HomeCategory({required this.category, required this.books});

  final BookCategory category;
  final List<Book> books;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final InventoryApi _api = InventoryApi();

  /// One entry per book category that has something in it, in the catalogue's
  /// own order, each with the books a student may buy from it.
  List<_HomeCategory> _categorySections = [];
  List<Book> _randomBooks = [];
  UserDetail? _userDetail;
  bool _isLoadingProducts = true;

  /// Why the catalogue is empty, when it is empty for a reason worth saying.
  String? _loadError;

  /// Reservations waiting at the counter — the app's own reason to show a
  /// badge. The API has no notifications of any kind; what a student needs to
  /// be told is that a book is ready to collect, and that is in the orders.
  int _readyForPickupCount = 0;

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
    });
    await Future.wait([
      _fetchBooks(),
      _fetchUserData(),
      _fetchReadyForPickupCount(),
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
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  // ------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _fetchUserData();
    _fetchReadyForPickupCount();
  }

  Future<void> _fetchReadyForPickupCount() async {
    // The badge reads the student's *own* reservations, so it needs their
    // signed session — orders scoped by a bare student number are refused now.
    // Without a session there is nobody to count for, so skip quietly rather
    // than let me.php answer 401: the badge is not worth a sign-in prompt.
    final session = await StudentSessionStore.read();

    if (session.isEmpty) return;

    try {
      final reservations = await _api.myReservations();
      if (!mounted) return;

      setState(() {
        _readyForPickupCount = reservations
            .where((r) => r.status == ReservationStatus.readyForPickup)
            .length;
      });
    } on ApiException catch (error) {
      // A badge is not worth interrupting the screen for.
      debugPrint('Could not count ready reservations: $error');
    }
  }

  /// Reads the real book categories and the books in each.
  ///
  /// One section per category, in the catalogue's own order. The recommended
  /// row is built from the union of everything on the way through, so it does
  /// not need a separate read of the whole catalogue.
  Future<void> _fetchBooks() async {
    try {
      final categories = await _api.categories(forMyYear: true);

      final sections = <_HomeCategory>[];
      final everything = <int, Book>{};

      for (final category in categories) {
        final books = await _api.booksInCategory(category.id, forMyYear: true);
        if (books.isEmpty) continue;

        sections.add(_HomeCategory(category: category, books: books));
        for (final book in books) {
          everything[book.id] = book;
        }
      }

      if (!mounted) return;

      // Ten at random, chosen once per fetch so the row does not reshuffle on
      // every rebuild.
      final shuffled = everything.values.toList()..shuffle(Random());

      setState(() {
        _categorySections = sections;
        _randomBooks = shuffled.take(10).toList();
        _loadError = null;
        _isLoadingProducts = false;
      });
      return;
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _categorySections = [];
        _randomBooks = [];
        _loadError = error.message(AppLocalizations.of(context));
        _isLoadingProducts = false;
      });
      return;
    }
  }

  Future<void> _fetchUserData() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) return;

    final detail = await StudentDirectory.fetch();

    if (!mounted || detail == null) return;

    setState(() => _userDetail = detail);
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
                _fetchReadyForPickupCount();
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
                  if (_readyForPickupCount > 0)
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
                          _readyForPickupCount > 99 ? '99+' : '$_readyForPickupCount',
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
  /// One section per book category that has books, and a mixed row underneath.
  List<Widget> _buildCategorySections(BuildContext context) {
    final sections = <Widget>[];
    final lang = AppLocalizations.of(context)!;
    final khmer = lang.locale.languageCode == 'km';

    for (final section in _categorySections) {
      final books = section.books;
      if (books.isEmpty) continue;

      final title = section.category.nameFor(khmer: khmer);
      final categoryId = section.category.id;

      sections.add(
        CategorySectionWidget(
          title: title,
          books: books,
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductScreen(
                  categoryId: categoryId,
                  categoryTitle: title,
                  initialBooks: books,
                ),
              ),
            );
          },
          onBookTap: (book) => _openBook(context, book),
        ),
      );

      sections.add(SizedBox(height: Height15));
    }

    if (sections.isEmpty) {
      sections.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              _loadError ?? lang.translate('no items found'),
              textAlign: TextAlign.center,
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

    if (_randomBooks.isNotEmpty) {
      sections.add(SizedBox(height: Height5));
      sections.add(
        RecommendedProductsSection(
          title: lang.translate('general product'),
          books: _randomBooks,
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductScreen()),
            );
          },
          onBookTap: (book) => _openBook(context, book),
        ),
      );
    }

    return sections;
  }

  void _openBook(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(book: book)),
    );
  }
}

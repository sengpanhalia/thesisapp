import 'package:flutter/material.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/book_category.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/product_screen.dart';
import 'package:thesisapp/view/user/search_screen.dart';

// ---------------------------------------------------------------------------
// Browse screen.
//
// The real book categories, from `GET /api/v1/categories.php` — original
// copies, black-and-white photocopies, printed, colour — each with a count of
// the books in it a student may actually buy. This used to group by the empty
// `year_level` and show one heap; the catalogue's genuine categories now sit
// behind the tiles, plus an "all books" tile at the front.
// ---------------------------------------------------------------------------
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

/// One tile: a real category, or the whole catalogue (`category == null`).
class _BrowseGroup {
  const _BrowseGroup({required this.category, required this.count});

  final BookCategory? category;
  final int count;

  bool get isEverything => category == null;
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController searchController = TextEditingController();
  final InventoryApi _api = InventoryApi();

  List<_BrowseGroup> _groups = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      final categories = await _api.categories(forMyYear: true);
      if (!mounted) return;

      // "All books" leads, then one tile per category. Its count is the sum of
      // the per-category counts, which is what the server counted as sellable.
      final total = categories.fold<int>(0, (sum, c) => sum + c.bookCount);

      setState(() {
        _groups = [
          _BrowseGroup(category: null, count: total),
          for (final category in categories)
            _BrowseGroup(category: category, count: category.bookCount),
        ];
        _loadError = null;
        _isLoading = false;
      });
      return;
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message(AppLocalizations.of(context));
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return Container(
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
                /// Search Bar
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
      
                const SizedBox(height: MgPd15),
      
                /// Title
                Text(
                  lang.translate('category'),
                  style: TextStyle(
                    fontSize: fontHeadTitle,
                    fontWeight: FontWeight.bold,
                    fontFamily: getFontFamily(context),
                  ),
                ),
      
                const SizedBox(height: MgPd15),
      
                /// Category Grid
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: GText1),
                    ),
                  )
                else if (_groups.isEmpty)
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
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _groups.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      return _buildCategoryItem(_groups[index]);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _openGroup(_BrowseGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductScreen(
          categoryId: group.category?.id,
          categoryTitle: _titleFor(group),
        ),
      ),
    );
  }

  String _titleFor(_BrowseGroup group) {
    final category = group.category;
    if (category == null) {
      return AppLocalizations.of(context)!.translate('books');
    }

    return category.nameFor(
      khmer: AppLocalizations.of(context)!.locale.languageCode == 'km',
    );
  }

  Widget _buildCategoryItem(_BrowseGroup group) {
    final title = _titleFor(group);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openGroup(group),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: StrokeSearchBar, width: 1.5),
            ),
            child: Center(
              child: _categoryIcon(group),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$title (${group.count})',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontText,
              fontWeight: FontWeight.w500,
              fontFamily: getFontFamily(context),
            ),
          ),
        ],
      ),
    );
  }

  /// The whole catalogue gets the book artwork; a category gets an icon.
  Widget _categoryIcon(_BrowseGroup group) {
    if (group.isEverything) {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Image.asset('assets/book.png', fit: BoxFit.contain),
      );
    }

    return const Icon(Icons.category_rounded, size: 36, color: GText1);
  }
}

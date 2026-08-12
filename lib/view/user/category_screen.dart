import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/product_screen.dart';
import 'package:thesisapp/view/user/search_screen.dart';
import 'package:thesisapp/model/category_model.dart';

// ---------------------------------------------------------------------------
// Category screen — fetches categories from API
// ---------------------------------------------------------------------------
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const String _baseUrl = ApiConfig.baseUrl;

  final TextEditingController searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_categories.php'),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final List categoriesJson = (data['categories'] as List?) ?? const [];
          setState(() {
            _categories = categoriesJson
                .whereType<Map<String, dynamic>>()
                .map(CategoryModel.fromJson)
                .toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
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
                else if (_categories.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'មិនមានប្រភេទទំនិញទេ',
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
                    itemCount: _categories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      return _buildCategoryItem(_categories[index]);
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
      MaterialPageRoute(builder: (_) => SearchScreen(baseUrl: _baseUrl)),
    );
  }

  void _openCategory(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductScreen(
          categoryId:    category.id,    // FK-based filter (preferred)
          categoryName:  category.name,  // fallback display
          categoryTitle: category.getTitle(context),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    final title = category.getTitle(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openCategory(category),
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
              child: _categoryIcon(category.name),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
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

  /// Returns a fitting icon for the category name.
  /// Falls back to a generic tag icon for unknown categories.
  Widget _categoryIcon(String name) {
    final key = name.trim().toLowerCase();

    // Try asset image first for known categories
    const assetMap = <String, String>{
      'book':      'assets/book.png',
      'books':     'assets/book.png',
      'shirt':     'assets/tshirt.png',
      't-shirt':   'assets/tshirt.png',
      't-shirts':  'assets/tshirt.png',
      'material':  'assets/material.png',
      'materials': 'assets/material.png',
    };

    final assetPath = assetMap[key];
    if (assetPath != null) {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      );
    }

    // Generic icon for dynamic categories added by admin
    return const Icon(Icons.category_rounded, size: 36, color: GText1);
  }
}

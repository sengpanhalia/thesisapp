import 'package:flutter/material.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/product_screen.dart';
import 'package:thesisapp/view/user/search_screen.dart';

class CategoryModel {
  final String name;       // translation key (e.g. "books")
  final String image;
  final String dbCategory; // exact value stored in DB (e.g. "Book")

  const CategoryModel({
    required this.name,
    required this.image,
    required this.dbCategory,
  });
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const String _baseUrl = ApiConfig.baseUrl;

  final TextEditingController searchController = TextEditingController();

  final List<CategoryModel> categoryList = const [
    CategoryModel(name: "books",     image: "assets/book.png",     dbCategory: "Book"),
    CategoryModel(name: "t-shirts",  image: "assets/tshirt.png",   dbCategory: "Shirt"),
    CategoryModel(name: "materials", image: "assets/material.png", dbCategory: "Materials"),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return SafeArea(
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: getFontFamily(context),
                ),
              ),

              const SizedBox(height: MgPd15),

              /// Category Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final category = categoryList[index];

                  return _buildCategoryItem(category);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchScreen(baseUrl: _baseUrl)),
    );
  }

  void _openCategory(CategoryModel category) {
    final lang = AppLocalizations.of(context)!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductScreen(
          categoryName: category.dbCategory,  // DB value for API filter
          categoryTitle: lang.translate(category.name),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    final lang = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openCategory(category),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: StrokeSearchBar, width: 1.5),
            ),
            child: Image.asset(category.image, fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          Text(
            lang.translate(category.name),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: getFontFamily(context),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/model/product.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String baseUrl;
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.baseUrl,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const String baseUrl = ApiConfig.baseUrl;
  List<Product> relatedProducts = [];
  void _openFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullImageView(imageUrl: imageUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double basePrice = double.tryParse(widget.product.price) ?? 0.0;
    final double originalPrice = basePrice;
    final String category = widget.product.category.trim();
    final String author = widget.product.author.trim();
    final String pages = widget.product.pages.trim();
    final String language = widget.product.language.trim();
    final String year = widget.product.year.trim();
    final int stockQuantity = widget.product.stockQuantity;
    final bool isOutOfStock = widget.product.isOutOfStock;
    final Color stockColor = isOutOfStock
        ? Colors.redAccent
        : const Color(0xFF2E7D32);
    final String? imageUrl = widget.product.image!.startsWith('http')
        ? widget.product.image
        : '${widget.baseUrl}/uploads/products/${widget.product.image}';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: const Text(
          'ព័ត៌មានលម្អិត',
          style: TextStyle(fontFamily: 'KhmerMool1', fontSize: 22),
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
                          child: CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: GBackground1,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.broken_image_rounded, size: 48),
                            ),
                          ),
                        ),
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
                                    // const Icon(
                                    //   Icons.fullscreen_rounded,
                                    //   size: 16,
                                    //   color: TextColor,
                                    // ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'មើលរូបភាព',
                                      style: TextStyle(
                                        fontFamily: UKFontFamily,
                                        fontSize: 12,
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
                    widget.product.name,
                    style: TextStyle(
                      fontFamily: UKFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: TitleColor,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: Height5),
                  Text(
                    'អ្នកនិពន្ធ: $author',
                    style: TextStyle(
                      fontFamily: UKFontFamily,
                      fontSize: 16,
                      color: TextColor,
                    ),
                  ),
                  SizedBox(height: Height10),
                  Text(
                    '​៛ ${basePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: UKFontFamily,
                      fontSize: 24,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isOutOfStock
                          ? 'អស់ពីស្តុក'
                          : 'នៅមានក្នុងស្តុក: $stockQuantity',
                      style: TextStyle(
                        fontFamily: UKFontFamily,
                        fontSize: 16,
                        color: stockColor,
                      ),
                    ),
                  ),
                  SizedBox(height: Height15),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: CardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        _SpecItem(
                          label: 'ទំព័រទាំងអស់',
                          value: pages.isNotEmpty ? pages : '—',
                        ),
                        const _SpecDivider(),
                        _SpecItem(
                          label: 'ភាសា',
                          value: language.isNotEmpty ? language : '—',
                        ),
                        const _SpecDivider(),
                        const _SpecDivider(),
                        _SpecItem(
                          label: 'ឆ្នាំបោះពុម្ព',
                          value: year.isNotEmpty ? year : '—',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Height20),
                  Text(
                    'ព័ត៌មានលម្អិត',
                    style: TextStyle(
                      fontFamily: UKFontFamily,
                      fontSize: 16,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height10),
                  Container(width: 90, height: 2, color: GText1),
                  SizedBox(height: Height15),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontFamily: UKFontFamily,
                      fontSize: 14,
                      color: TextColor,
                      height: LineHegiht,
                      letterSpacing: 0.7,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: Height20),
                  Text(
                    'សៀវភៅណែនាំ',
                    style: TextStyle(
                      fontFamily: UKFontFamily,
                      fontSize: 16,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height10),
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: relatedProducts.length,
                    itemBuilder: (context, index){
                      final product = relatedProducts[index];
                      final productImage = (product.image ?? '').trim();
                      final imageUrl = productImage.startsWith('http')
                          ? productImage
                          : '$baseUrl/uploads/products/$productImage';

                      return 
                  })
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullImageView extends StatelessWidget {
  const _FullImageView({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'រូបភាពពេញទំហំ',
          style: TextStyle(fontFamily: 'KhmerMool1', fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.broken_image_rounded, size: 64)),
          ),
        ),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: UKFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: TitleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: UKFontFamily,
              fontSize: 11,
              color: Colors.brown[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecDivider extends StatelessWidget {
  const _SpecDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: StrokeSearchBar);
  }
}

Widget buildRecommendProduct(){
  return Container(
    
  );
}
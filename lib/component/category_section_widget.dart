import 'package:flutter/material.dart';
import 'package:thesisapp/component/card_product.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/product.dart';
import 'package:thesisapp/theme_color.dart';

class CategorySectionWidget extends StatelessWidget {
  final String title;
  final List<Product> products;
  final String baseUrl;
  final VoidCallback onSeeAll;
  final void Function(Product) onProductTap;

  const CategorySectionWidget({
    super.key,
    required this.title,
    required this.products,
    required this.baseUrl,
    required this.onSeeAll,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontTitle,
                color: TextColor,
                fontWeight: FontWeight.w700,
                fontFamily: getFontFamily(context),
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                lang.translate("see all"),
                style: TextStyle(
                  fontSize: fontText,
                  color: GText1,
                  fontWeight: FontWeight.w500,
                  fontFamily: getFontFamily(context),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: Height10),

        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final productImage = (product.image ?? '').trim();
              final imageUrl = buildProductImageUrl(baseUrl, productImage);

              return SizedBox(
                width: 165,
                child: BuildCardProduct(
                  onTap: () => onProductTap(product),
                  productName: product.name,
                  productPrice: product.price,
                  imageUrl: imageUrl,
                  productImage: productImage,
                  author: product.author,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

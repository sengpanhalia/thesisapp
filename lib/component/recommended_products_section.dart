import 'package:flutter/material.dart';
import 'package:thesisapp/component/card_product.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/theme_color.dart';

class RecommendedProductsSection extends StatelessWidget {
  final String title;
  final List<Book> books;
  final VoidCallback onSeeAll;
  final void Function(Book) onBookTap;

  const RecommendedProductsSection({
    super.key,
    required this.title,
    required this.books,
    required this.onSeeAll,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSubtitle,
                color: TextColor,
                fontWeight: FontWeight.w700,
                fontFamily: getFontFamily(context),
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                lang.translate('see all'),
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

        SizedBox(height: Height15),

        // ── 2-column grid ──
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
              onTap: () => onBookTap(book),
              productName: book.titleFor(
                khmer: Localizations.localeOf(context).languageCode == 'km',
              ),
              priceLabel: formatMoney(book.price),
              imageUrl: buildProductImageUrl(book.imageUrl),
              author: book.author,
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:thesisapp/component/card_product.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/theme_color.dart';

class CategorySectionWidget extends StatelessWidget {
  final String title;
  final List<Book> books;
  final VoidCallback onSeeAll;
  final void Function(Book) onBookTap;

  const CategorySectionWidget({
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
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = books[index];

              return SizedBox(
                width: 165,
                child: BuildCardProduct(
                  onTap: () => onBookTap(book),
                  productName: book.titleFor(
                    khmer: Localizations.localeOf(context).languageCode == 'km',
                  ),
                  priceLabel: formatMoney(book.price),
                  imageUrl: buildProductImageUrl(book.imageUrl),
                  author: book.author,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

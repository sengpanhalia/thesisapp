import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

class BuildCardProduct extends StatelessWidget {
  final VoidCallback? onTap;
  final String productName;
  final String author;

  /// Already formatted — `$12.50`, or a dash when the catalogue holds no
  /// price. Money is never formatted inside a card.
  final String priceLabel;

  /// Null when the catalogue has no picture for this book, which is most of
  /// them; the card then shows its placeholder rather than a broken image.
  final String? imageUrl;

  const BuildCardProduct({
    super.key,
    required this.onTap,
    required this.productName,
    required this.priceLabel,
    required this.imageUrl,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.only(bottom: Height10),
      // padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StrokeSearchBar, width: 1),
      ),
      child: GestureDetector(
        onTap: () {
          onTap?.call();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: imageUrl == null
                      ? bookPlaceholder()
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return imageLoading();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return bookPlaceholder();
                          },
                        ),
                ),
              ),
            ),
            SizedBox(height: Height5),
            Padding(
              padding: const EdgeInsets.only(left: MgPd10, right: MgPd10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: fontTitle,
                      color: TextColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: getFontFamily(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // SizedBox(height: Height5),
                  Text(
                    author,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: fontText,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Height5),
                  Text(
                    priceLabel,
                    style: TextStyle(
                      fontSize: fontSubtitle,
                      color: GText1,
                      fontWeight: FontWeight.w600,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  SizedBox(height: Height10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget imageLoading() {
  return Container(
    color: Colors.white.withValues(alpha: 0.45),
    alignment: Alignment.center,
    child: const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(color: GText1, strokeWidth: 2),
    ),
  );
}

/// Shown where a book has no picture. The university's catalogue has none for
/// any book today, so this is what most cards draw — a spinner there would
/// promise an image that is never coming.
Widget bookPlaceholder() {
  return Container(
    color: Colors.white.withValues(alpha: 0.45),
    alignment: Alignment.center,
    child: const Icon(Icons.menu_book_rounded, size: 40, color: GText1),
  );
}

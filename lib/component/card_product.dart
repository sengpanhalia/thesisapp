import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

class BuildCardProduct extends StatelessWidget {
  final VoidCallback? onTap;
  final String productName;
  final String productPrice;
  final String imageUrl;
  final String productImage;
  const BuildCardProduct({
    super.key,
    required this.onTap,
    required this.productName,
    required this.productPrice,
    required this.imageUrl,
    required this.productImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.only(bottom: Height10),
      // padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
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
                  child: productImage.isEmpty
                      ? imageLoading()
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return imageLoading();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return imageLoading();
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
                      fontSize: 18,
                      color: TextColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: UKFontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // SizedBox(height: Height5),
                  Text(
                    productName,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 14,
                      color: TextColor,
                      fontFamily: UKFontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Height5),
                  Text(
                    '\$$productPrice',
                    style: TextStyle(
                      fontSize: 14,
                      color: GText1,
                      fontWeight: FontWeight.w600,
                      fontFamily: UKFontFamily,
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

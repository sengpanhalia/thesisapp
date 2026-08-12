import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thesisapp/theme_color.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const InfoCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: fontSubtitle,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Colors.grey[600];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: fontText, color: muted)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: fontTitle,
            fontWeight: valueWeight ?? FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class OrderItemRow extends StatelessWidget {
  final String name;
  final int qty;
  final double? originalPrice;
  final String imageUrl;

  const OrderItemRow({
    super.key,
    required this.name,
    required this.qty,
    this.originalPrice,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 54,
            height: 54,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 54,
              height: 54,
              color: Colors.grey[200],
              child: const Icon(Icons.image_rounded, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: fontText,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: $qty',
                      style: GoogleFonts.poppins(
                        fontSize: fontText,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (originalPrice != null)
                Text(
                  '\$${originalPrice!.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: fontText,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

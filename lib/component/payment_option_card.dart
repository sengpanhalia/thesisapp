import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thesisapp/theme_color.dart';

class PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const PaymentOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primary : Colors.transparent,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    // style: GoogleFonts.poppins(
                    //   fontWeight: FontWeight.w600,
                    //   fontSize: fontSubtitle,
                    //   color: Colors.black87,
                    // ),
                    style: TextStyle(
                      fontSize: fontSubtitle,
                      fontWeight: FontWeight.w700,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    // style: GoogleFonts.poppins(
                    //   fontSize: fontText,
                    //   color: Colors.grey[600],
                    style: TextStyle(
                      fontSize: fontText,
                      fontWeight: FontWeight.w500,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? primary : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

class Button extends StatelessWidget {
  final String title;
  final String? icon;
  final VoidCallback? onTap;

  const Button({super.key, required this.title, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Round25),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: IconOrangeColor,
          borderRadius: BorderRadius.circular(Round25),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: MgPd10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: WhiteColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(icon!),
                  ),
                ),
              if (icon != null) SizedBox(height: Height5),
              SizedBox(width: Width15),
              Text(
                title,
                style: TextStyle(
                  color: WhiteColor,
                  fontFamily: UKFontFamily,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

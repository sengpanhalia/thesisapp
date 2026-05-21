import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

Widget customizeAlertDialog({
  required String title,
  required String content,
  void Function()? cancelOnTap,
  void Function()? onTap,
  required String choice_1,
  required String choice_2,

}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: UKFontFamily,
              color: BlackColor,
            ),
          ),

          const SizedBox(height: 20),

          /// Content
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontFamily: UKFontFamily,
              color: TextColor,
            ),
          ),

          const SizedBox(height: 25),

          /// Buttons
          Row(
            children: [
              /// Cancel Button
              Expanded(
                child: GestureDetector(
                  onTap: cancelOnTap,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      choice_1,
                      style: TextStyle(
                        color: Sapphire,
                        fontSize: 14,
                        fontFamily: UKFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              /// Divider
              Container(width: 1, height: 35, color: Colors.grey.shade400),

              /// Confirm Button
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      choice_2,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontFamily: UKFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

Widget textGradient(String text, TextStyle style) {
  return ShaderMask(
    shaderCallback: (bounds) => LinearGradient(
      colors: [GText1, GText2, GText3],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
    child: Text(
      text,
      style: style.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ), // Set color to white for gradient
    ),
  );
}

LinearGradient gradientColor({
  Alignment begin = Alignment.topLeft,
  Alignment end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [GBackground1, GBackground2, GBackground3, GBackground4],
    stops: const [0.0, 0.3, 0.7, 1.0],
  );
}

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const AppButton({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC96A28),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

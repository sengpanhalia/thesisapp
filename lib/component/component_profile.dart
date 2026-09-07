import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

class ComponentProfile extends StatelessWidget {
  final String title;
  final String image;
  final void Function()? onTap;
  const ComponentProfile({
    super.key,
    required this.title,
    this.onTap,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        decoration: BoxDecoration(
          color: WhiteColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          // Tinted to the USEA brand navy — the source PNG is orange.
          child: Image.asset(
            image,
            height: 30,
            width: 30,
            color: ButtonColor,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: getFontFamily(context),
          fontSize: fontTitle,
          color: TextColor,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: ButtonColor,
      ),
    );
  }
}

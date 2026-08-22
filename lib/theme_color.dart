import 'package:flutter/material.dart';
import 'package:thesisapp/util/api_config.dart';

const UKFontFamily = "SiemReap";
const UKFontFamilyMool1 = "KhmerMool1";
const UEFontFamily = "Poppins";

String getFontFamily(BuildContext context) {
  try {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'km' ? UKFontFamily : UEFontFamily;
  } catch (e) {
    return UKFontFamily;
  }
}
String getFontFamilyMool1(BuildContext context) {
  try {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'km' ? UKFontFamilyMool1 : UEFontFamily;
  } catch (e) {
    return UKFontFamilyMool1;
  }
}

/// The catalogue's picture for a row, ready to fetch — or null when it has
/// none, which is when the screen shows a placeholder instead.
///
/// The inventory API hands back a finished `image_url` rather than a bare
/// filename, so there is no folder to guess at here: absolute values are used
/// as they are, and a site-relative one is resolved against the API's own host.
String? buildProductImageUrl(String? imageUrl) =>
    ApiConfig.resolveImageUrl(imageUrl);

const WhiteColor = Color(0xFFFFFFFF);
const RedColor = Color(0xFFEE0000);
const GreenColor = Color(0xFF2CB037);
const YellowColor = Color(0xFFFFEB3B);
final StrokeColor = Color(0xFF9A9288).withOpacity(0.5);
const TranparentColor = Colors.transparent;
const BlackColor = Color(0xFF000000);
const Sapphire = Color(0xFF002060);
final processColor = Color(0xFF0B0C7F).withOpacity(0.9);


const GBackground1 = Color(0xFFFDF6EE);
const GBackground2 = Color(0xFFFAF0E4);
const GBackground3 = Color(0xFFF4E2CC);
const GBackground4 = Color(0xFFECD0AE);

const StrokeSearchBar = Color(0xFFE8E6E2);

const GText1 = Color(0xFF0B0C7F);   // USEA brand navy (was orange)
const GText2 = Color(0xFF08096B);
const GText3 = Color(0xFF06074F);
final GText4 = Color(0xFF040538).withOpacity(0.7);

const Sapphire2 = Color(0xFF002060);
const Sapphire3 = Color.fromARGB(255, 10, 47, 122);
const Sapphire4 = Color.fromARGB(255, 58, 106, 212);
const Sapphire5 = Color.fromARGB(255, 20, 76, 187);

const TextColor = Color(0xFF5E574F);
const TitleColor = Color(0xFF2C2822);
const TextSoftColor = Color(0xFFB8B2A8);
const GreyColor = Color(0xFFD9D9D9);

const ButtonColor = Color(0xFF0B0C7F);   // USEA brand navy
const CardColor = Color(0xFFFDF8F2);


const StrokeCardColor = Color(0xFFFDF6EE);

const IconColor = Color(0xFF2C2C2C);
const IconOrangeColor = Color(0xFF0B0C7F);

const ColorNavBar = Color(0xFFFAEBD7);

const SoftGreen = Color(0xFFAFE4B5);

final checkboxColor = Color(0xFF0B0C7F).withOpacity(0.7);

const double ZeroPixel = 0.0;

const double LineHegiht = 1.5;

const double fontText = 12;
const double fontTitle = 16;
const double fontSubtitle = 14;
const double fontHeadTitle = 18;
const double fontAppBar = 20;

// Margin and Padding
const double MgPd5 = 5;
const double MgPd10 = 10;
const double MgPd15 = 15;
const double MgPd20 = 20;
const double MgPd25 = 25;

const double Round5 = 5;
const double Round10 = 10;
const double Round15 = 15;
const double Round20 = 20;
const double Round25 = 25;

const double Height5 = 5;
const double Height10 = 10;
const double Height15 = 15;
const double Height20 = 20;
const double Height25 = 25;
const double Height30 = 30;
const double Height35 = 35;
const double Height40 = 40;
const double Height45 = 45;
const double Height50 = 50;
const double Height70 = 70;

const double Width5 = 5;
const double Width10 = 10;
const double Width15 = 15;
const double Width20 = 20;
const double Width25 = 25;
const double Width30 = 30;
const double Width35 = 35;
const double Width40 = 40;
const double Width45 = 45;
const double Width50 = 50;


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/student_directory.dart';
import 'package:thesisapp/theme_color.dart';

const _profileCardColor = Color(0xFFFBFAF8);
const _profileCardBorder = Color(0xFFF0E9E1);
const _profileDividerColor = Color(0xFFBDB7AE);
const _profileBackFill = Color(0xFFF8F1E8);
const _profileBackBorder = Color(0xFFE9DED1);
const _profileShadow = Color(0x16000000);
const _profileHorizontalPadding = 24.0;
const _profileRowRadius = 14.0;
const _profileRowGap = 7.0;
const _profileLabelWidth = 108.0;

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  UserDetail? _userDetail;

  Future<void> _fetchUserData() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) return;

    final detail = await StudentDirectory.fetch();

    if (!mounted || detail == null) return;

    setState(() => _userDetail = detail);
  }

  String getNameUser(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final isEnglish = lang?.locale.languageCode == 'en';
    if (isEnglish) {
      return _userDetail?.name_en ?? "";
    } else {
      return _userDetail?.name_kh ?? "";
    }
  }

  String getGenderUser(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final isEnglish = lang?.locale.languageCode == 'en';
    final gender = _userDetail?.gender.trim() ?? "";
    final normalized = gender.toLowerCase();

    if (isEnglish) {
      if (gender == "ប្រុស" || normalized == "m") return "Male";
      if (gender == "ស្រី" || normalized == "f") return "Female";
      return gender;
    }

    if (normalized == "male" || normalized == "m") return "ប្រុស";
    if (normalized == "female" || normalized == "f") return "ស្រី";
    return gender;
  }

  String getDateOfBirthUser(BuildContext context) {
    final rawDate = _userDetail?.date_of_birth.trim() ?? "";
    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate == null) return rawDate;

    final lang = AppLocalizations.of(context);
    final isEnglish = lang?.locale.languageCode == 'en';
    final months = isEnglish
        ? const [
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "Jun",
            "Jul",
            "Aug",
            "Sep",
            "Oct",
            "Nov",
            "Dec",
          ]
        : const [
            "មករា",
            "កុម្ភៈ",
            "មីនា",
            "មេសា",
            "ឧសភា",
            "មិថុនា",
            "កក្កដា",
            "សីហា",
            "កញ្ញា",
            "តុលា",
            "វិច្ឆិកា",
            "ធ្នូ",
          ];
    final day = parsedDate.day.toString().padLeft(2, '0');

    return "$day-${months[parsedDate.month - 1]}-${parsedDate.year}";
  }

  String getUserFaculty(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final isEnglish = lang?.locale.languageCode == 'en';

    if (!isEnglish) {
      return _userDetail?.faculty_name ?? "";
    }

    final List<Map<String, String>> faculties = [
      {
        "kh": "មហាវិទ្យាល័យ វិទ្យាសាស្ត្រ និងបច្ចេកវិទ្យា",
        "en": "Faculty of Science and Technology",
      },
      {
        "kh": "មហាវិទ្យាល័យ សេដ្ឋកិច្ច ពាណិជ្ជកម្ម និងទេសចរណ៍",
        "en": "Faculty of Economics, Business and Tourism",
      },
      {
        "kh": "មហាវិទ្យាល័យ សិល្បៈ មនុស្សសាស្រ្ត និងភាសា",
        "en": "Faculty of Arts, Humanities and Languages",
      },
      {
        "kh": "មហាវិទ្យាល័យ វិទ្យាសាស្ត្រសង្គម និងនីតិសាស្រ្ត",
        "en": "Faculty of Social Sciences and Law",
      },
    ];

    for (final faculty in faculties) {
      if (faculty["kh"] == _userDetail?.faculty_name) {
        return faculty["en"]!;
      }
    }

    return _userDetail?.faculty_name ?? "";
  }

  // String getUserMajor(BuildContext context) {
  //   final lang = AppLocalizations.of(context);
  //   final isEnglish = lang?.locale.languageCode == 'en';

  //   if (!isEnglish) {
  //     return _userDetail?.faculty_name ?? "";
  //   }

  //   final List<Map<String, String>> faculties = [
  //     {
  //       "kh": "មហាវិទ្យាល័យ វិទ្យាសាស្ត្រ និងបច្ចេកវិទ្យា",
  //       "en": "Faculty of Science and Technology",
  //     },
  //     {
  //       "kh": "មហាវិទ្យាល័យ គ្រប់គ្រងទេសចរណ៍",
  //       "en": "Faculty of Tourism Management",
  //     },
  //     {
  //       "kh": "មហាវិទ្យាល័យ ភាសាបរទេស",
  //       "en": "Faculty of Foreign Languages",
  //     },
  //     {
  //       "kh": "មហាវិទ្យាល័យ សេដ្ឋកិច្ច និងហិរញ្ញវត្ថុ",
  //       "en": "Faculty of Economics and Finance",
  //     },
  //   ];

  //   for (final faculty in faculties) {
  //     if (faculty["kh"] == _userDetail?.faculty_name) {
  //       return faculty["en"]!;
  //     }
  //   }

  //   return _userDetail?.faculty_name ?? "";
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final nameUser = getNameUser(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WhiteColor,
        surfaceTintColor: WhiteColor,
        shadowColor: Colors.transparent,
        toolbarHeight: 58,
        title: Text(
          'ព័ត៌មានផ្ទាល់ខ្លួន',
          style: TextStyle(
            fontFamily: 'KhmerMool1',
            fontSize: fontHeadTitle,
            fontWeight: FontWeight.w500,
            color: TitleColor,
          ),
        ),
        leadingWidth: 48,
        leading: Center(
          child: Tooltip(
            message: lang.translate('back'),
            child: Material(
              color: _profileBackFill,
              shape: const CircleBorder(
                side: BorderSide(color: _profileBackBorder),
              ),
              child: InkResponse(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: TitleColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: WhiteColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _profileHorizontalPadding,
              vertical: Height10,
            ),
            child: Column(
              children: [
                ListInfo(
                  context: context,
                  title: lang.translate('student_id'),
                  subTitle: _userDetail?.student_id ?? "",
                ),
                const SizedBox(height: _profileRowGap),
                ListInfo(
                  context: context,
                  title: lang.translate('full_name'),
                  subTitle: nameUser,
                ),
                const SizedBox(height: _profileRowGap),
                ListInfo(
                  context: context,
                  title: lang.translate('gender'),
                  subTitle: getGenderUser(context),
                ),
                const SizedBox(height: _profileRowGap),
                ListInfo(
                  context: context,
                  title: lang.translate('date_of_birth'),
                  subTitle: getDateOfBirthUser(context),
                ),
                const SizedBox(height: _profileRowGap),
                ListInfo(
                  context: context,
                  title: lang.translate('faculty'),
                  subTitle: getUserFaculty(context),
                ),
                const SizedBox(height: _profileRowGap),
                ListInfo(
                  context: context,
                  title: lang.translate('major'),
                  subTitle: _userDetail?.major_name ?? "",
                ),
                const SizedBox(height: _profileRowGap),
                CardYear(
                  context: context,
                  year: _userDetail?.year_name ?? "",
                  semester: _userDetail?.semester_name ?? "",
                  stage_name: _userDetail?.stage_name ?? "",
                  term_name: _userDetail?.term_name ?? "",
                  academic_year: _userDetail?.academic_year ?? "",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget ListInfo({
  required BuildContext context,
  required String title,
  required String subTitle,
}) {
  return Container(
    decoration: BoxDecoration(
      color: _profileCardColor,
      borderRadius: BorderRadius.circular(_profileRowRadius),
      border: Border.all(color: _profileCardBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: _profileShadow,
          offset: Offset(0, 3),
          blurRadius: 5,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: _profileLabelWidth,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: fontSubtitle,
                  fontFamily: getFontFamily(context),
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: TextColor,
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: _profileDividerColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subTitle,
                style: TextStyle(
                  fontSize: fontSubtitle,
                  fontFamily: getFontFamily(context),
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: TextColor,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget CardYear({
  required BuildContext context,
  required String year,
  required String semester,
  required String stage_name,
  required String term_name,
  required String academic_year,
}) {
  final lang = AppLocalizations.of(context)!;

  // Values may arrive already labelled; keep the card label as the heading and
  // show only the useful part underneath.
  String strip(String value, String label) {
    final v = value.trim();
    return v.startsWith(label) ? v.substring(label.length).trim() : v;
  }

  String displayValue(String value) {
    final v = value.trim();
    return v.isEmpty ? '-' : v;
  }

  final yearValue = strip(year, lang.translate('student_study_year'));
  var semesterValue = strip(semester, lang.translate('semester'));
  final promotionSource = stage_name.trim().isNotEmpty ? stage_name : term_name;
  final stageValue = strip(promotionSource, lang.translate('promotion'));
  var academicYearValue = strip(academic_year, lang.translate('acad_year'));

  final semesterParts = semesterValue
      .split(RegExp('[\\u00B7\\u2022]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (semesterParts.length > 1) {
    semesterValue = semesterParts.first;
    if (academicYearValue.isEmpty) {
      academicYearValue = semesterParts.skip(1).join(' ');
    }
  }

  final entries = <MapEntry<String, String>>[
    MapEntry(lang.translate('student_study_year'), displayValue(yearValue)),
    MapEntry(lang.translate('semester'), displayValue(semesterValue)),
    MapEntry(lang.translate('promotion'), displayValue(stageValue)),
    MapEntry(lang.translate('acad_year'), displayValue(academicYearValue)),
  ];

  if ([year, semester, stage_name, term_name, academic_year].every(
    (v) => v.trim().isEmpty,
  )) {
    return const SizedBox.shrink();
  }

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: _profileCardColor,
      borderRadius: BorderRadius.circular(_profileRowRadius),
      border: Border.all(color: _profileCardBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: _profileShadow,
          offset: Offset(0, 3),
          blurRadius: 5,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries
            .map((e) => Expanded(
                  child: _CardYearItem(
                    context: context,
                    title: e.key,
                    value: e.value,
                  ),
                ))
            .toList(),
      ),
    ),
  );
}

Widget _CardYearItem({
  required BuildContext context,
  required String title,
  required String value,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontText,
          fontFamily: getFontFamily(context),
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: const Color(0xFF8D877F),
        ),
      ),
      const SizedBox(height: 4),
      // Long values stay on one line to preserve the four-column shape.
      Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSubtitle,
          fontFamily: getFontFamily(context),
          color: TextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/student_directory.dart';
import 'package:thesisapp/theme_color.dart';

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

  String getStatusUser(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final isEnglish = lang?.locale.languageCode == 'en';
    if (!isEnglish) {
      return _userDetail?.status_name ?? "";
    } else {
      final List<Map<String, String>> status = [
        {
          "kh": "កំពុងសិក្សា",
          "en": "Studying",
        },
        {
          "kh": "បញ្ចប់ការសិក្សា",
          "en": "Graduated",
        },
        {
          "kh": "បោះបង់ការសិក្សា",
          "en": "Dropout",
        },
      ];
      for (final status in status) {
        if (status["kh"] == _userDetail?.status_name) {
          return status["en"]!;
        }
      }
      return _userDetail?.status_name ?? "";
    }
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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Text(
          'ព័ត៌មានផ្ទាល់ខ្លួន',
          style: TextStyle(fontFamily: 'KhmerMool1', fontSize: fontAppBar),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: gradientColor(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MgPd20,
              vertical: Height15,
            ),
            child: Column(
              children: [
                ListInfo(
                  context: context,
                  title: lang.translate('student_id'),
                  subTitle: _userDetail?.student_id ?? "",
                ),
                SizedBox(height: Height15),
                ListInfo(
                  context: context,
                  title: lang.translate('full_name'),
                  subTitle: nameUser,
                ),
                SizedBox(height: Height15),
                ListInfo(
                  context: context,
                  title: lang.translate('status'),
                  subTitle: getStatusUser(context),
                ),
                SizedBox(height: Height15),
                ListInfo(
                  context: context,
                  title: lang.translate('date_of_birth'),
                  subTitle: _userDetail?.date_of_birth ?? "",
                ),
                SizedBox(height: Height15),
                ListInfo(
                  context: context,
                  title: lang.translate('faculty'),
                  subTitle: getUserFaculty(context),
                ),
                SizedBox(height: Height15),
                ListInfo(
                  context: context,
                  title: lang.translate('major'),
                  subTitle: _userDetail?.major_name ?? "",
                ),
                SizedBox(height: Height15),
                CardYear(
                  context: context,
                  year: _userDetail?.year_name ?? "",
                  semester: _userDetail?.semester_name ?? "",
                  stage_name: _userDetail?.stage_name ?? "",
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

Widget ListInfo({required BuildContext context, required String title, required String subTitle}) {
  return Container(
    decoration: BoxDecoration(
      color: CardColor,
      borderRadius: BorderRadius.circular(Round10),
      border: Border.all(color: WhiteColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: BlackColor.withOpacity(0.2),
          offset: Offset(0, 4),
          blurRadius: 6,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(MgPd10),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: fontTitle,
                  fontFamily: getFontFamily(context),
                  color: TextColor,
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                subTitle,
                style: TextStyle(
                  fontSize: fontTitle,
                  fontFamily: getFontFamily(context),
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
  required String academic_year,
}) {
  final lang = AppLocalizations.of(context)!;

  // The server sends year and semester already labelled (e.g. "ឆ្នាំទី 3",
  // "ឆមាសទី 2 · 2024–2025") and usually sends nothing for the promotion or the
  // academic year. The old four-column card therefore duplicated those labels,
  // left two columns empty, and squeezed the long semester text until the row
  // looked broken. Show instead a centred, wrapping row of just the facts that
  // are present — self-labelled ones as they are, the others with their label —
  // so nothing overflows and nothing is repeated or blank.
  final items = <String>[
    if (year.trim().isNotEmpty) year.trim(),
    if (semester.trim().isNotEmpty) semester.trim(),
    if (stage_name.trim().isNotEmpty) '${lang.translate('promotion')} ${stage_name.trim()}',
    if (academic_year.trim().isNotEmpty) '${lang.translate('acad_year')} ${academic_year.trim()}',
  ];

  if (items.isEmpty) return const SizedBox.shrink();

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: CardColor,
      borderRadius: BorderRadius.circular(Round10),
      border: Border.all(color: WhiteColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: BlackColor.withOpacity(0.2),
          offset: Offset(0, 4),
          blurRadius: 6,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Height10,
        horizontal: MgPd10,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((text) => _YearChip(context: context, text: text))
            .toList(),
      ),
    ),
  );
}

Widget _YearChip({required BuildContext context, required String text}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: GBackground3,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: fontTitle,
        fontFamily: getFontFamily(context),
        color: TextColor,
      ),
    ),
  );
}

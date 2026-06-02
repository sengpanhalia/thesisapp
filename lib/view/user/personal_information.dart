import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/user_api.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  UserDetail? _userDetail;

  Future<void> _fetchUserData() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(APIStLoginKh),
        body: {'student_id': authUser.student_id, 'pwd': authUser.pwd},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final userData =
              (decoded['user_data'] as List?) ??
              (decoded['student_users'] as List?) ??
              const [];
          final details = userData
              .whereType<Map<String, dynamic>>()
              .map(UserDetail.fromJson)
              .toList();

          if (!mounted) return;
          setState(() {
            _userDetail = details.isNotEmpty ? details.first : null;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load user detail: $e');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: const Text(
          'ព័ត៌មានផ្ទាល់ខ្លួន',
          style: TextStyle(fontFamily: 'KhmerMool1', fontSize: 22),
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
                  title: "អត្តលេខ",
                  subTitle: _userDetail?.student_id ?? "",
                ),
                SizedBox(height: Height15),
                ListInfo(
                  title: "គោត្តនាម-នាម",
                  subTitle: _userDetail?.name_kh ?? "",
                ),
                SizedBox(height: Height15),
                ListInfo(
                  title: "អត្តលេខ",
                  subTitle: _userDetail?.status_name ?? "",
                ),
                SizedBox(height: Height15),
                ListInfo(
                  title: "ថ្ងៃខែឆ្នាំកំណើត",
                  subTitle: _userDetail?.date_of_birth ?? "",
                ),
                SizedBox(height: Height15),
                ListInfo(
                  title: "មហាវិទ្យាល័យ",
                  subTitle: _userDetail?.faculty_name ?? "",
                ),
                SizedBox(height: Height15),
                ListInfo(
                  title: "មុខជំនាញ",
                  subTitle: _userDetail?.major_name ?? "",
                ),
                SizedBox(height: Height15),
                CardYear(
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

Widget ListInfo({required String title, required String subTitle}) {
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
                  fontSize: 16,
                  fontFamily: UKFontFamily,
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
                  fontSize: 16,
                  fontFamily: UKFontFamily,
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
  required String year,
  required String semester,
  required String stage_name,
  required String academic_year,
}) {
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
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: _CardYearItem(title: 'ឆ្នាំទី', value: year),
          ),
          Expanded(
            flex: 10,
            child: _CardYearItem(title: 'ឆមាសទី', value: semester),
          ),
          Expanded(
            flex: 10,
            child: _CardYearItem(title: 'វគ្គទី', value: stage_name),
          ),
          Expanded(
            flex: 15,
            child: _CardYearItem(title: 'ឆ្នាំសិក្សា', value: academic_year),
          ),
        ],
      ),
    ),
  );
}

Widget _CardYearItem({required String title, required String value}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          fontFamily: UKFontFamily,
          color: TextColor,
        ),
      ),
      SizedBox(height: Height10),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontSize: 16,
            fontFamily: UKFontFamily,
            color: TextColor,
          ),
        ),
      ),
    ],
  );
}

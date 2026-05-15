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
  bool _isLoadingUser = true;

  Future<void> _fetchUserData() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
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
            _isLoadingUser = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load user detail: $e');
    }

    if (!mounted) return;
    setState(() => _isLoadingUser = false);
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
          child: Column(
            children: [ListInfo(title: "អត្តលេខ", subTitle: "")],
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
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 100,
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
          Text(
            subTitle,
            style: TextStyle(
              fontSize: 16,
              fontFamily: UKFontFamily,
              color: TextColor,
            ),
          ),
        ],
      ),
    ),
  );
}

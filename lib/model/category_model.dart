import 'package:flutter/material.dart';
import 'package:thesisapp/localization/app_localizations.dart';

class CategoryModel {
  final int id;
  final String name;
  final String nameKh;

  const CategoryModel({
    required this.id,
    required this.name,
    this.nameKh = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      nameKh: json['name_kh']?.toString() ?? json['nameKh']?.toString() ?? '',
    );
  }

  String getTitle(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final isEnglish = lang?.locale.languageCode == 'en';
    if (isEnglish) {
      return name.isNotEmpty ? name : nameKh;
    } else {
      return nameKh.isNotEmpty ? nameKh : name;
    }
  }
}

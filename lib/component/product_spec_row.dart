import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

class SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const SpecItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: TitleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: 11,
              color: Colors.brown[400],
            ),
          ),
        ],
      ),
    );
  }
}

class SpecDivider extends StatelessWidget {
  const SpecDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: StrokeSearchBar);
  }
}

class ProductSpecRow extends StatelessWidget {
  final String pages;
  final String language;
  final String year;
  final String pagesLabel;
  final String languageLabel;
  final String yearLabel;

  const ProductSpecRow({
    super.key,
    required this.pages,
    required this.language,
    required this.year,
    required this.pagesLabel,
    required this.languageLabel,
    required this.yearLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: CardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SpecItem(
            label: pagesLabel,
            value: pages.isNotEmpty ? pages : '—',
          ),
          const SpecDivider(),
          SpecItem(
            label: languageLabel,
            value: language.isNotEmpty ? language : '—',
          ),
          const SpecDivider(),
          SpecItem(
            label: yearLabel,
            value: year.isNotEmpty ? year : '—',
          ),
        ],
      ),
    );
  }
}

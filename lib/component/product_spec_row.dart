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
              fontSize: fontSubtitle,
              fontWeight: FontWeight.bold,
              color: TitleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: fontText,
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

/// The three facts the catalogue actually holds about a book.
///
/// It used to show pages, language and printing year — none of which the
/// inventory API returns. What it does return for a book is its code, its
/// publisher, its ISBN and the year level it is set for, so those are what is
/// shown. A field the catalogue left blank shows a dash rather than an
/// invented value.
class ProductSpecRow extends StatelessWidget {
  final String code;
  final String publisher;
  final String isbn;
  final String codeLabel;
  final String publisherLabel;
  final String isbnLabel;

  const ProductSpecRow({
    super.key,
    required this.code,
    required this.publisher,
    required this.isbn,
    required this.codeLabel,
    required this.publisherLabel,
    required this.isbnLabel,
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
          SpecItem(label: codeLabel, value: code.isNotEmpty ? code : '—'),
          const SpecDivider(),
          SpecItem(
            label: publisherLabel,
            value: publisher.isNotEmpty ? publisher : '—',
          ),
          const SpecDivider(),
          SpecItem(label: isbnLabel, value: isbn.isNotEmpty ? isbn : '—'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/admin/stock_in.dart';
import 'package:thesisapp/view/admin/stock_out.dart';
import 'package:thesisapp/view/admin/stock_request.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  static const List<OverviewItems> overviewItems = [
    OverviewItems(
      imageIcon: 'assets/home.png',
      title: 'ការដកសម្ភារៈ',
      total: '1000',
      screen: StockOut(),
    ),
    OverviewItems(
      imageIcon: 'assets/home.png',
      title: 'ការដាក់សម្ភារៈ',
      total: '1000',
      screen: StockIn(),
    ),
    OverviewItems(
      imageIcon: 'assets/home.png',
      title: 'ការស្នើសម្ភារៈ',
      total: '1000',
      screen: StockRequest(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: const Text(
          'Overview',
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: overviewItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // number of columns
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1, // card width/height ratio
                  ),
                  itemBuilder: (context, index) {
                    final item = overviewItems[index];

                    return _cardOverView(
                      context: context,
                      imageIcon: item.imageIcon,
                      title: item.title,
                      total: item.total,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item.screen),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OverviewItems {
  final String imageIcon;
  final String title;
  final String total;
  final Widget screen;

  const OverviewItems({
    required this.imageIcon,
    required this.title,
    required this.total,
    required this.screen,
  });
}

Widget _cardOverView({
  required BuildContext context,
  required String imageIcon,
  required String title,
  required String total,
  void Function()? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 140,
      width: 170,
      decoration: BoxDecoration(
        color: CardColor,
        border: Border.all(color: WhiteColor, width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BlackColor.withOpacity(0.2),
            blurRadius: 4.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: getFontFamily(context),
                  fontSize: 16,
                  color: TextColor,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: CardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  height: 25,
                  width: 25,
                  child: Image.asset(imageIcon),
                ),
              ),
            ],
          ),
          Text(
            total,
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: 16,
              color: TextColor,
            ),
          ),
        ],
      ),
    ),
  );
}

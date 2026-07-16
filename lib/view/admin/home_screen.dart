import 'package:flutter/material.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/admin/history_screen.dart';
import 'package:thesisapp/view/admin/overview_screen.dart';
import 'package:thesisapp/view/admin/view_stock.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const List<_AdminFeatureItem> _featureItems = [
    _AdminFeatureItem(
      image: 'assets/home.png',
      title: 'Home',
      screen: OverviewScreen(),
    ),
    _AdminFeatureItem(
      image: 'assets/graduate.png',
      title: 'Graduate',
      screen: ViewStock(),
    ),
    _AdminFeatureItem(
      image: 'assets/order.png',
      title: 'Order',
      screen: HistoryScreen(),
    ),
  ];

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'អរុណសួស្តី,'; // Good Morning in Khmer
    } else if (hour < 17) {
      return 'ទិវាសួស្តី,'; // Good Afternoon in Khmer
    } else if (hour < 20) {
      return 'សាយន្តសួស្តី,'; // Afternoon in Khmer
    } else {
      return 'រាត្រីសួស្តី,'; // Evening in Khmer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        leadingWidth: MediaQuery.of(context).size.width,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: MgPd20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getGreeting(),
                    style: TextStyle(
                      fontSize: 14,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  SizedBox(height: Height5),
                  textGradient(
                    'សាកលវិទ្យាល័យ​ សៅស៍អុីសថ៍អេយសៀ',
                    TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontFamily: 'KhmerMool1',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: MgPd20),
        //     child: CircleAvatar(
        //       radius: 22,
        //       backgroundColor: Colors.white,
        //       child: CircleAvatar(
        //         radius: 20,
        //         backgroundColor: Colors.white.withValues(alpha: 0.95),
        //         backgroundImage: profileImageUrl.isNotEmpty
        //             ? CachedNetworkImageProvider(profileImageUrl)
        //             : null,
        //         child: _isLoadingUser
        //             ? const SizedBox(
        //                 width: 18,
        //                 height: 18,
        //                 child: CircularProgressIndicator(strokeWidth: 2),
        //               )
        //             : profileImageUrl.isEmpty
        //             ? const Icon(Icons.person, color: Colors.black45)
        //             : null,
        //       ),
        //     ),
        //   ),
        // ],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MgPd20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardAdminProfile(context),
                  SizedBox(height: Height15),
                  Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  SizedBox(height: Height15),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _featureItems.map((item) {
                      return _CardFeature(
                        context: context,
                        imageIcon: item.image,
                        title: item.title,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item.screen),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminFeatureItem {
  const _AdminFeatureItem({
    required this.image,
    required this.title,
    required this.screen,
  });

  final String image;
  final String title;
  final Widget screen;
}

Widget _CardAdminProfile(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: Height25, vertical: Height15),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/image_profile.jpg'),
            ),
            SizedBox(width: Width25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome, ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: TextColor,
                    fontFamily: getFontFamily(context),
                  ),
                ),
                Text(
                  'Thida Harotey',
                  style: TextStyle(
                    fontSize: 20,
                    // fontWeight: FontWeight.bold,
                    color: TextColor,
                    fontFamily: getFontFamily(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _CardFeature({
  required BuildContext context,
  required String imageIcon,
  required String title,
  void Function()? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 120,
      width: 120,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 35, width: 35, child: Image.asset(imageIcon)),
          SizedBox(height: Height10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TextColor,
              fontFamily: getFontFamily(context),
            ),
          ),
        ],
      ),
    ),
  );
}

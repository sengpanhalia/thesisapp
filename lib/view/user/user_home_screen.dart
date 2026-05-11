import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/carousel_slider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/theme_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

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

  void _openSearch() {
    context.read<NavigationProvider>().setIndex(1);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Matching the warm gradient from your design
          gradient: gradientColor(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MgPd20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            color: TextColor,
                            fontFamily: UKFontFamily,
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
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('assets/image.JPG'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Height15),
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: StrokeSearchBar, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Colors.black45),
                      const SizedBox(width: Width5),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          readOnly: true,

                          onTap: _openSearch,
                          decoration: InputDecoration(
                            fillColor: Colors.transparent,
                            hintText: 'ស្វែងរក...',
                            // hintStyle: GoogleFonts.poppins(
                            //   fontSize: 13,
                            //   color: Colors.black45,
                            //   fontWeight: FontWeight.w500,
                            // ),
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: TextSoftColor,
                              // fontWeight: FontWeight.w500,
                              fontFamily: UKFontFamily,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Height15),
                CarouselSliderWidget(
                  images: [
                    'assets/slide1.png',
                    'assets/slide2.png',
                    'assets/slide3.png',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

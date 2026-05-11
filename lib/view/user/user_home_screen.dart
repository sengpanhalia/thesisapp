import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _fetchProducts() async {
    final url = Uri.parse('$_baseUrl/get_products.php');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final List productsJson = (data['products'] as List?) ?? const [];
          setState(() {
            _products = productsJson
                .whereType<Map<String, dynamic>>()
                .map(ProductModel.fromJson)
                .toList();
            _isLoadingProducts = false;
          });
          return;
        }
      }
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    setState(() => _isLoadingProducts = false);
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: Height15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'សៀវភៅប្រចាំឆមាស',
                      style: TextStyle(
                        fontSize: 16,
                        color: TextColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: UKFontFamily,
                      ),
                    ),
                    GestureDetector(
                      child: Text(
                        'មើលទាំងអស់',
                        style: TextStyle(
                          fontSize: 13,
                          color: GText1,
                          fontFamily: UKFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Height10),
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemBuilder: (context, index){
                    return 
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

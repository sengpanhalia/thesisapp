import 'package:flutter/material.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/theme_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'អរុណសួស្តី'; // Good Morning in Khmer
    } else if (hour < 17) {
      return 'ទិវាសួស្តី'; // Good Afternoon in Khmer
    } else if (hour < 20) {
      return 'សាយន្តសួស្តី'; // Afternoon in Khmer
    } else {
      return 'រាត្រីសួស្តី'; // Evening in Khmer
    }
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
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: UKFontFamily,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

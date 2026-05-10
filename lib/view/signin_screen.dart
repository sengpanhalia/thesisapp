import 'package:flutter/material.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/home_page.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // Matching the warm gradient from your design
              gradient: gradientColor(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 100),
                Image.asset('assets/logo_app.png', height: 150),
                SizedBox(height: 20),
                Text(
                  'សាកលវិទ្យាល័យ សៅស៍អុីសថ៍អេយសៀ',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'KhmerMool1',
                    // fontWeight: FontWeight.bold,
                    color: TextColor, // USEA Deep Blue
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'University of South-East Asia',
                  style: TextStyle(
                    fontSize: 22,
                    letterSpacing: 1.5,
                    color: TextColor,
                    fontFamily: UEFontFamily,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'សូមស្វាគមន៍',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'KhmerMool1',
                    // fontWeight: FontWeight.bold,
                    color: TextColor, // USEA Deep Blue
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '3',
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: 'tacteng',
                    fontWeight: FontWeight.w500,
                    color: TextColor, // USEA Deep Blue
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: MediaQuery.of(context).size.width * 0.80,
                  decoration: BoxDecoration(
                    color: CardColor,
                    borderRadius: BorderRadius.circular(Round15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(MgPd20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "អត្តលេខនិស្សិត",
                          style: TextStyle(
                            fontSize: 16,
                            color: TextColor,
                            fontFamily: UKFontFamily,
                          ),
                        ),
                        SizedBox(height: Height5),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'អត្តលេខនិស្សិត',
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Round15),
                              borderSide: BorderSide(
                                color: StrokeColor,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Round15),
                              borderSide: BorderSide(
                                color: StrokeColor,
                                width: 1,
                              ),
                            ),
                            hintStyle: TextStyle(
                              color: TextSoftColor,
                              fontFamily: UKFontFamily,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: MgPd10,
                              vertical: MgPd15,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        SizedBox(height: Height10),
                        Text(
                          "លេខកូដសម្ងាត់",
                          style: TextStyle(
                            fontSize: 16,
                            color: TextColor,
                            fontFamily: UKFontFamily,
                          ),
                        ),
                        SizedBox(height: Height5),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Round15),
                              borderSide: BorderSide(
                                color: StrokeColor,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Round15),
                              borderSide: BorderSide(
                                color: StrokeColor,
                                width: 1,
                              ),
                            ),
                            hintText: 'លេខកូដសម្ងាត់',
                            hintStyle: TextStyle(
                              color: TextSoftColor,
                              fontFamily: UKFontFamily,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: MgPd10,
                              vertical: MgPd15,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        SizedBox(height: Height30),
                        AppButton(
                          title: 'ចូលគណនី',
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:thesisapp/provider/theme_provider.dart";
import "package:thesisapp/splash_screen.dart";
import "package:thesisapp/util/app_theme.dart";

void main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider())

        ],
        child: Consumer(builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // themeMode: themeProvider.theme,
            theme: AppThemes.light,
            // darkTheme: AppThemes.dark,
            home: SplashScreen(),
          );
        }),
      ),
    );
  }
}
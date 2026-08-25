import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/localization/language_provider.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/provider/theme_provider.dart';
import 'package:thesisapp/splash_screen.dart';
import 'package:thesisapp/util/app_theme.dart';
import 'package:thesisapp/theme_color.dart';

import 'package:thesisapp/service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app starts first; notifications set themselves up in the background.
  // Firebase Cloud Messaging blocks on Google Play services, and a device
  // without working Play services — an emulator, most often — leaves that call
  // pending forever. Awaiting it here held runApp() back and stuck the app on
  // its splash logo. Its own errors are the service's to log.
  runApp(const MyApp());
  unawaited(NotificationService.initialize().catchError((_) {}));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        // ADD THIS
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) => CartProvider(context.read<AuthProvider>()),

          update: (context, authProvider, cartProvider) {
            if (cartProvider == null) {
              return CartProvider(authProvider);
            }

            cartProvider.bindAuth(authProvider);

            return cartProvider;
          },
        ),
      ],

      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            theme: AppThemes.light.copyWith(
              textTheme: AppThemes.light.textTheme.apply(
                fontFamily: languageProvider.locale.languageCode == 'km'
                    ? UKFontFamily
                    : UEFontFamily,
              ),
            ),

            locale: languageProvider.locale,

            localizationsDelegates: const [
              AppLocalizationDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            supportedLocales: const [Locale('en'), Locale('km')],

            home: SplashScreen(),
          );
        },
      ),
    );
  }
}

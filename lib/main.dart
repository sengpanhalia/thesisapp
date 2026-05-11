import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/provider/theme_provider.dart';
import 'package:thesisapp/splash_screen.dart';
import 'package:thesisapp/util/app_theme.dart';

void main() {
  runApp(const MyApp());
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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            theme: AppThemes.light,

            // darkTheme: AppThemes.dark,
            // themeMode: themeProvider.themeMode,
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}

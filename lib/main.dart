import 'package:flutter/material.dart';
import 'views/splash_screen.dart';
import 'package:uni_links/uni_links.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
 Widget build(
      BuildContext context) {
    return const MaterialApp(
      home: SplashScreen(),
    );
  }
}

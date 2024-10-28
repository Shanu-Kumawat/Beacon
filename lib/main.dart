import 'package:beacon/features/auth/screens/signin_screen.dart';
import 'package:beacon/theme/apptheme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beacon',
      theme: AppTheme.darkTheme,
      home: const SigninScreen(),
    );
  }
}

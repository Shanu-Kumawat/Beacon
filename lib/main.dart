import 'package:beacon/core/providers/firebase_providers.dart';
import 'package:beacon/features/auth/screens/signin_screen.dart';
import 'package:beacon/features/home/screens/home_screen.dart';
import 'package:beacon/features/navigation/screens/destination_search_screen.dart';
import 'package:beacon/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beacon',
      theme: AppTheme.darkTheme,
      home: StreamBuilder(
          stream: ref.watch(authProvider).userChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data != null) {
              return const HomeScreen();
            }
            return const SigninScreen();
          }),
    );
  }
}

import 'package:beacon/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void logOut(WidgetRef ref) {
    ref.read(authControllerProvider).signOutFromGoogle();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon'), // The title in the AppBar
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout), // Logout icon
            onPressed: () => logOut(ref),
          ),
        ],
      ),
      body: const Placeholder(),
    );
  }
}

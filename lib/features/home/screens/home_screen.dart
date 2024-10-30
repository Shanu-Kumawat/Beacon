import 'package:beacon/core/common/custom_icon_button.dart';
import 'package:beacon/features/auth/controller/auth_controller.dart';
import 'package:beacon/features/environment/screens/scan_environment_screen.dart';
import 'package:beacon/features/navigation/screens/destination_search_screen.dart';
import 'package:beacon/theme/apptheme.dart';
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
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            "BEACON",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontSize: 25,
            ),
          ),
          backgroundColor: AppTheme.surface,
          elevation: 20,
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.logout), // Logout icon
              onPressed: () => logOut(ref),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 70),
              const Text(
                "AR Navigation Assistant",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 40.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text(
                "Get voice-guided navigation and accessibility support",
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 120),
              CustomIconButton(
                label: "Start Navigation",
                icon: Icons.navigation_outlined,
                color: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSearchScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),
              CustomIconButton(
                label: "Scan Environment",
                icon: Icons.camera_alt_outlined,
                color: Colors.grey[700]!,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanEnvironmentScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),
              CustomIconButton(
                label: "Emergency",
                icon: Icons.emergency_outlined,
                color: Colors.red,
                onPressed: () {
                  // Emergency logic
                },
              ),
              const Spacer(),
            ],
          ),
        ));
  }
}

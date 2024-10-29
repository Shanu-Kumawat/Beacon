import 'package:beacon/core/constants/constants.dart';
import 'package:beacon/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:beacon/theme/apptheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SigninScreen extends StatelessWidget {
  const SigninScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  size: 80,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing * 2.5),
              // Welcome Text
              const Text(
                'Welcome to Beacon',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: 'Welcome to Nav Assist',
              ),
              const SizedBox(height: AppTheme.spacing),
              const Text(
                'Your accessible navigation companion',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Google Sign In Button
              const GoogleSignInButton(),
              const SizedBox(height: AppTheme.spacing * 2),
            ],
          ),
        ),
      ),
    );
  }
}

class GoogleSignInButton extends ConsumerWidget {
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.isLoading = false,
  });

  void signInWithGoogle(WidgetRef ref) {
    ref.read(authControllerProvider).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialButton(
      onPressed: isLoading ? null : () => signInWithGoogle(ref),
      color: AppTheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(
          color: AppTheme.textPrimary.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing * 1.5,
        vertical: AppTheme.spacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            Constants.googleLogo,
            height: 30,
          ),
          const SizedBox(width: AppTheme.spacing * 0.75),
          Text(
            isLoading ? 'Signing in...' : 'Continue with Google',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

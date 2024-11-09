import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _makeEmergencyCall(BuildContext context) async {
  try {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    // Get emergency contact from Firestore
    final medicalDataDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medical_data')
        .doc('current')
        .get();

    if (!medicalDataDoc.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emergency contact found')),
        );
      }
      return;
    }

    final emergencyContact = medicalDataDoc.data()?['emergencyContact'] as String?;
    if (emergencyContact == null || emergencyContact.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emergency contact number available')),
        );
      }
      return;
    }

    // Show confirmation dialog
    if (context.mounted) {
      bool? shouldCall = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Emergency Call'),
            content: Text('Call emergency contact: $emergencyContact?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Call'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldCall != true) return;
    }

    // Make the call
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: emergencyContact,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making emergency call: ${e.toString()}')),
      );
    }
  }
}

// Modified Quick Action Button
Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    BuildContext context,
    ) {
  return ElevatedButton(
    onPressed: () => _makeEmergencyCall(context),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(title),
      ],
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _makeEmergencyCall(BuildContext context, String phoneNumber, String contactName) async {
    bool? shouldCall = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Emergency Call'),
          content: Text('Do you want to call $contactName?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Call'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldCall != true) return;

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      debugPrint('Error launching emergency call: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to make emergency call')),
        );
      }
    }
  }

  Future<void> _sendLocationSMS(BuildContext context, String phoneNumber, String contactName) async {
    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.sms,
      ].request();

      if (statuses[Permission.location]!.isDenied ||
          statuses[Permission.sms]!.isDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location and SMS permissions are required')),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      Placemark place = placemarks[0];
      String address =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

      // Prepare SMS content
      String message = 'Emergency: My current location is:\n$address\n' +
          'GPS Coordinates: ${position.latitude}, ${position.longitude}\n' +
          'Google Maps Link: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      // Launch SMS
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw 'Could not launch SMS';
      }
    } catch (e) {
      debugPrint('Error sending location SMS: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send location SMS')),
        );
      }
    }
  }

  Widget _buildEmergencyButton(
      BuildContext context,
      String title,
      String phoneNumber,
      IconData icon,
      Color color,
      ) {
    bool isLocalContact = title.contains('Local');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: GestureDetector(
        onLongPress: isLocalContact
            ? () => _sendLocationSMS(context, phoneNumber, title)
            : null,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: () => _makeEmergencyCall(context, phoneNumber, title),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      phoneNumber,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (isLocalContact)
                      const Text(
                        'Long press to share location via SMS',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rest of the build method remains the same
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Tap on any contact to make an emergency call",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            // Police Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Police",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildEmergencyButton(
              context,
              "Police Emergency",
              "100",
              Icons.local_police,
              Colors.blue[700]!,
            ),
            _buildEmergencyButton(
              context,
              "Local Police Station",
              "7001026887",
              Icons.location_city,
              Colors.blue[600]!,
            ),

            // Medical Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Medical",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildEmergencyButton(
              context,
              "Ambulance",
              "102",
              Icons.local_hospital,
              Colors.red[700]!,
            ),
            _buildEmergencyButton(
              context,
              "Local Hospital",
              "7001026887",
              Icons.medical_services,
              Colors.red[600]!,
            ),

            // Fire Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Fire",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildEmergencyButton(
              context,
              "Fire Emergency",
              "101",
              Icons.local_fire_department,
              Colors.orange[700]!,
            ),

            // Other Emergency Numbers
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Other Emergency Numbers",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildEmergencyButton(
              context,
              "Women Helpline",
              "1091",
              Icons.people,
              Colors.purple[700]!,
            ),
            _buildEmergencyButton(
              context,
              "Child Helpline",
              "1098",
              Icons.child_care,
              Colors.green[700]!,
            ),
            _buildEmergencyButton(
              context,
              "National Emergency Number",
              "112",
              Icons.emergency,
              Colors.red[900]!,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
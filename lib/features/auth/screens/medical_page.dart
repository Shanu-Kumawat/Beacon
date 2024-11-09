// Import necessary Flutter and Firebase packages
import 'package:beacon/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model class to store user medical information
class UserMedicalData {
  final String email;
  final String name;
  final int age;
  final String condition;
  final List<String> medications;
  final String emergencyContact;
  final String gender;
  final String bloodgroup;

  // Constructor requiring all fields
  UserMedicalData({
    required this.email,
    required this.name,
    required this.age,
    required this.condition,
    required this.medications,
    required this.emergencyContact,
    required this.gender,
    required this.bloodgroup,
  });

  // Convert user medical data to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'condition': condition,
      'medications': medications,
      'emergencyContact': emergencyContact,
      'gender': gender,
      'bloodgroup': bloodgroup,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}

// StatefulWidget for the medical details form page
class MedicalDetailsPage extends StatefulWidget {
  const MedicalDetailsPage({super.key});

  @override
  _MedicalDetailsPageState createState() => _MedicalDetailsPageState();
}

class _MedicalDetailsPageState extends State<MedicalDetailsPage> {
  // Form key for form validation
  final _formKey = GlobalKey<FormState>();

  // Firebase instances
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Text controllers for form fields
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  // Dropdown selection values
  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _isLoading = false;

  // Predefined options for dropdowns
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // Method to save medical details to Firestore
  Future<void> _saveMedicalDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get current authenticated user
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      // Create medical data object
      final medicalData = UserMedicalData(
        email: user.email!,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender!,
        condition: _conditionController.text.trim(),
        medications: _medicationsController.text.split(',').map((e) => e.trim()).toList(),
        emergencyContact: _emergencyContactController.text.trim(),
        bloodgroup: _selectedBloodGroup!,
      );

      // Save user email and timestamp to users collection
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Save current medical data
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_data')
          .doc('current')
          .set(medicalData.toMap());

      // Add to medical history
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_history')
          .add(medicalData.toMap());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical details saved successfully')),
      );

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      // Show error message if save fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving medical details: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the main UI scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Details'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      // Main container with gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.grey.shade200,
            ],
          ),
        ),
        // Scrollable form content
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information section
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                // Name input field
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Age and Gender row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _ageController,
                        label: 'Age',
                        prefixIcon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (int.tryParse(value!) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedGender,
                        items: genderOptions,
                        label: 'Gender',
                        prefixIcon: Icons.people_outline,
                        onChanged: (value) => setState(() => _selectedGender = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Medical Information section
                const Text(
                  'Medical Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                // Blood group dropdown
                _buildDropdown(
                  value: _selectedBloodGroup,
                  items: bloodGroupOptions,
                  label: 'Blood Group',
                  prefixIcon: Icons.bloodtype_outlined,
                  onChanged: (value) => setState(() => _selectedBloodGroup = value),
                ),
                const SizedBox(height: 16),
                // Medical condition input
                _buildTextField(
                  controller: _conditionController,
                  label: 'Medical Condition',
                  prefixIcon: Icons.medical_information_outlined,
                  maxLines: 2,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter your medical condition';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Medications input
                _buildTextField(
                  controller: _medicationsController,
                  label: 'Medications (comma-separated)',
                  prefixIcon: Icons.medication_outlined,
                  maxLines: 2,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter your medications';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Emergency Contact section
                Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                // Emergency contact input
                _buildTextField(
                  controller: _emergencyContactController,
                  label: 'Emergency Contact Number',
                  prefixIcon: Icons.emergency_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter emergency contact';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                // Save button with gradient
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withBlue(255),
                      ],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveMedicalDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Save Medical Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build styled text form fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: Colors.grey.shade800),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: validator,
      ),
    );
  }

  // Helper method to build styled dropdown form fields
  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData prefixIcon,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: TextStyle(color: Colors.grey.shade800)),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        onChanged: onChanged,
        validator: (value) => value == null ? 'This field is required' : null,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalInfoPage extends StatelessWidget {
  const MedicalInfoPage({super.key});

  Future<Map<String, dynamic>?> _fetchMedicalData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medical_data')
        .doc('current')
        .get();

    return docSnapshot.data();
  }

  void _showUpdateDialog(BuildContext context, Map<String, dynamic> currentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Medical Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: currentData['condition'],
                decoration: const InputDecoration(
                  labelText: 'Medical Condition',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: (currentData['medications'] as List<dynamic>).join(', '),
                decoration: const InputDecoration(
                  labelText: 'Medications',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: currentData['emergencyContact'],
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement update logic
              Navigator.of(context).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Information'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
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
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchMedicalData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text('No medical information found'),
              );
            }

            final data = snapshot.data!;
            final medications = (data['medications'] as List<dynamic>).join(', ');

            return RefreshIndicator(
              onRefresh: () async {
                // Convert Future<Map<String, dynamic>?> to Future<void>
                await _fetchMedicalData();
                return;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Enable scrolling even when content doesn't fill the screen
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.medical_information,
                                size: 40,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'],
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Age: ${data['age']} • ${data['gender']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoCard('Blood Group', data['bloodgroup']),
                        _buildInfoCard('Medical Condition', data['condition']),
                        _buildInfoCard('Medications', medications),
                        _buildInfoCard('Emergency Contact', data['emergencyContact']),
                        const SizedBox(height: 80), // Add padding at bottom for FAB
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final data = await _fetchMedicalData();
          if (data != null && context.mounted) {
            _showUpdateDialog(context, data);
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text('Update Info'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
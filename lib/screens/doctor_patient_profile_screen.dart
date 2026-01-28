import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_chat_screen.dart';
import '../services/user_service.dart';

class DoctorPatientProfileScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientProfileScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final doctor = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.green.shade800,
        actions: [
          if (doctor != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DoctorChatScreen(
                      doctorId: doctor.uid,
                      doctorName: 'Doctor',
                      patientId: patientId,
                      patientName: patientName,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(patientId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                    final email = userData?['email'] as String? ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.green.shade100,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Health Profile
            Text(
              'Health Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(patientId)
                  .collection('healthProfile')
                  .doc('profile')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No health profile available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                final profile = snapshot.data!.data() as Map<String, dynamic>;
                final age = profile['age'] as int? ?? 0;
                final gender = profile['gender'] as String? ?? 'Not specified';
                final allergies = profile['allergies'] as List<dynamic>? ?? [];
                final conditions = profile['conditions'] as List<dynamic>? ?? [];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: 'Age', value: age.toString()),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Gender', value: gender),
                        if (allergies.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Allergies:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allergies.map((allergy) {
                              return Chip(
                                label: Text(allergy.toString()),
                                backgroundColor: Colors.red.shade50,
                                labelStyle: TextStyle(color: Colors.red.shade700),
                              );
                            }).toList(),
                          ),
                        ],
                        if (conditions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Health Conditions:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: conditions.map((condition) {
                              return Chip(
                                label: Text(condition.toString()),
                                backgroundColor: Colors.orange.shade50,
                                labelStyle: TextStyle(color: Colors.orange.shade700),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Food Scan History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Food Scan History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show all scans
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(patientId)
                  .collection('scans')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No scan history available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final scan = doc.data() as Map<String, dynamic>;
                    final foodName = scan['foodName'] as String? ?? 'Unknown';
                    final status = scan['status'] as String? ?? 'safe';
                    final timestamp = scan['timestamp'] as Timestamp?;
                    final isSafe = status == 'safe';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSafe
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            isSafe ? Icons.check_circle : Icons.warning,
                            color: isSafe
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                        title: Text(foodName),
                        subtitle: timestamp != null
                            ? Text(_formatTimestamp(timestamp))
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSafe
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSafe
                                  ? Colors.green.shade300
                                  : Colors.orange.shade300,
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: isSafe
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (doctor != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DoctorChatScreen(
                              doctorId: doctor.uid,
                              doctorName: 'Doctor',
                              patientId: patientId,
                              patientName: patientName,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Start Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video call feature coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade600,
                      side: BorderSide(color: Colors.green.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

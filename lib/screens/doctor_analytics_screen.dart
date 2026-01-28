import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAnalyticsScreen extends StatelessWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctor = FirebaseAuth.instance.currentUser;
    
    if (doctor == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 20),

            // Overall Stats
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .where('doctorId', isEqualTo: doctor.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int totalPatients = 0;
                if (snapshot.hasData) {
                  totalPatients = snapshot.data!.docs.length;
                }

                return Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Total Patients',
                        value: totalPatients.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('dietPlans')
                            .where('doctorId', isEqualTo: doctor.uid)
                            .snapshots(),
                        builder: (context, dietSnapshot) {
                          int totalPlans = 0;
                          if (dietSnapshot.hasData) {
                            totalPlans = dietSnapshot.data!.docs.length;
                          }
                          return _AnalyticsCard(
                            title: 'Diet Plans',
                            value: totalPlans.toString(),
                            icon: Icons.restaurant_menu,
                            color: Colors.purple,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Food Scan Patterns
            Text(
              'Food Scan Patterns',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .where('doctorId', isEqualTo: doctor.uid)
                  .snapshots(),
              builder: (context, roomsSnapshot) {
                if (!roomsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = roomsSnapshot.data!.docs;
                final patientIds = rooms
                    .map((room) {
                      final data = room.data() as Map<String, dynamic>?;
                      return data?['userId'] as String?;
                    })
                    .where((id) => id != null && id.isNotEmpty)
                    .cast<String>()
                    .toList();

                if (patientIds.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No patient data available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: patientIds)
                      .snapshots(),
                  builder: (context, usersSnapshot) {
                    if (!usersSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Aggregate scan data
                    Map<String, int> unsafeFoods = {};
                    Map<String, int> safeFoods = {};

                    return FutureBuilder<List<QuerySnapshot>>(
                      future: Future.wait(
                        patientIds.map((id) => FirebaseFirestore.instance
                            .collection('users')
                            .doc(id)
                            .collection('scans')
                            .limit(50)
                            .get()),
                      ),
                      builder: (context, scansSnapshot) {
                        if (!scansSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        for (var scans in scansSnapshot.data!) {
                          for (var scan in scans.docs) {
                            final data = scan.data() as Map<String, dynamic>;
                            final foodName = data['foodName'] as String? ?? 'Unknown';
                            final status = data['status'] as String? ?? 'safe';

                            if (status == 'unsafe' || status == 'warning') {
                              unsafeFoods[foodName] = (unsafeFoods[foodName] ?? 0) + 1;
                            } else {
                              safeFoods[foodName] = (safeFoods[foodName] ?? 0) + 1;
                            }
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (unsafeFoods.isNotEmpty) ...[
                              Text(
                                'Most Unsafe Foods Detected',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(unsafeFoods.entries.toList()
                                    ..sort((a, b) => b.value.compareTo(a.value)))
                                  .take(5)
                                  .map((entry) => Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.warning,
                                            color: Colors.red.shade700,
                                          ),
                                          title: Text(entry.key),
                                          trailing: Text(
                                            '${entry.value} times',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              const SizedBox(height: 24),
                            ],
                            if (safeFoods.isNotEmpty) ...[
                              Text(
                                'Most Safe Foods Detected',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(safeFoods.entries.toList()
                                    ..sort((a, b) => b.value.compareTo(a.value)))
                                  .take(5)
                                  .map((entry) => Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.check_circle,
                                            color: Colors.green.shade700,
                                          ),
                                          title: Text(entry.key),
                                          trailing: Text(
                                            '${entry.value} times',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Generate Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report generation coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.description),
                label: const Text('Generate Full Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

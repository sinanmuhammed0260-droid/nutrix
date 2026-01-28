import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorCreateDietPlanScreen extends StatefulWidget {
  const DoctorCreateDietPlanScreen({super.key});

  @override
  State<DoctorCreateDietPlanScreen> createState() => _DoctorCreateDietPlanScreenState();
}

class _DoctorCreateDietPlanScreenState extends State<DoctorCreateDietPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _conditionController = TextEditingController();
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _snacksController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedPatientId;

  @override
  void dispose() {
    _planNameController.dispose();
    _patientIdController.dispose();
    _conditionController.dispose();
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _snacksController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveDietPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get patient name
      String patientName = 'Patient';
      if (_selectedPatientId != null) {
        final patientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_selectedPatientId)
            .get();
        patientName = patientDoc.data()?['displayName'] as String? ?? 'Patient';
      }

      await FirebaseFirestore.instance.collection('dietPlans').add({
        'doctorId': doctor.uid,
        'patientId': _selectedPatientId,
        'patientName': patientName,
        'planName': _planNameController.text.trim(),
        'condition': _conditionController.text.trim(),
        'meals': {
          'breakfast': _breakfastController.text.trim(),
          'lunch': _lunchController.text.trim(),
          'dinner': _dinnerController.text.trim(),
          'snacks': _snacksController.text.trim(),
        },
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diet plan created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating diet plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Diet Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _planNameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name *',
                  hintText: 'e.g., Diabetes Management Plan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter plan name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Patient selection
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chatRooms')
                    .where('doctorId', isEqualTo: doctor?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final patients = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Patient',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedPatientId,
                      items: patients.map((room) {
                        final data = room.data() as Map<String, dynamic>;
                        final userId = data['userId'] as String? ?? '';
                        final userName = data['userName'] as String? ?? 'Patient';
                        return DropdownMenuItem(
                          value: userId,
                          child: Text(userName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPatientId = value);
                      },
                    );
                  }
                  return TextFormField(
                    controller: _patientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Patient ID',
                      hintText: 'Enter patient ID',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionController,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  hintText: 'e.g., Diabetes, Hypertension',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Meal Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _breakfastController,
                decoration: const InputDecoration(
                  labelText: 'Breakfast',
                  hintText: 'Describe breakfast meal',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _lunchController,
                decoration: const InputDecoration(
                  labelText: 'Lunch',
                  hintText: 'Describe lunch meal',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _dinnerController,
                decoration: const InputDecoration(
                  labelText: 'Dinner',
                  hintText: 'Describe dinner meal',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _snacksController,
                decoration: const InputDecoration(
                  labelText: 'Snacks',
                  hintText: 'Describe snacks',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  hintText: 'Any additional instructions or notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDietPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Diet Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

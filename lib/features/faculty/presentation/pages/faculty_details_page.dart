import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyDetailsPage extends StatefulWidget {
  const FacultyDetailsPage({super.key});

  @override
  State<FacultyDetailsPage> createState() => _FacultyDetailsPageState();
}

class _FacultyDetailsPageState extends State<FacultyDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBranch;
  String? _selectedYear;
  String? _selectedSemester;
  final TextEditingController _subjectController = TextEditingController();
  bool _isLoading = false;

  final List<String> _branches = [
    'Information Technology',
    'Data Analytics',
    'Cyber Security',
  ];

  final List<String> _years = ['I', 'II'];

  List<String> get _semesters {
    if (_selectedYear == 'I') {
      return ['I', 'II'];
    } else if (_selectedYear == 'II') {
      return ['III', 'IV'];
    }
    return [];
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submitDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('faculty_subjects').add({
            'facultyId': user.uid,
            'facultyName': user.displayName,
            'branch': _selectedBranch,
            'year': _selectedYear,
            'semester': _selectedSemester,
            'subjectName': _subjectController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Details Added Successfully! You can add more.'),
                backgroundColor: Colors.green,
              ),
            );
            // Reset form to allow adding more
            _formKey.currentState!.reset();
            _subjectController.clear();
            setState(() {
              _selectedBranch = null;
              _selectedYear = null;
              _selectedSemester = null;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Faculty Class Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade500],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        color: Colors.white.withOpacity(0.95),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add Class & Subject',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Branch Dropdown
                                DropdownButtonFormField<String>(
                                  value: _selectedBranch,
                                  decoration: InputDecoration(
                                    labelText: 'Branch Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  items: _branches
                                      .map(
                                        (branch) => DropdownMenuItem(
                                          value: branch,
                                          child: Text(branch),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedBranch = value;
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Please select a branch'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Year Dropdown
                                DropdownButtonFormField<String>(
                                  value: _selectedYear,
                                  decoration: InputDecoration(
                                    labelText: 'Year',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  items: _years
                                      .map(
                                        (year) => DropdownMenuItem(
                                          value: year,
                                          child: Text(year),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedYear = value;
                                      _selectedSemester =
                                          null; // Reset semester
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Please select year'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Semester Dropdown
                                DropdownButtonFormField<String>(
                                  value: _selectedSemester,
                                  decoration: InputDecoration(
                                    labelText: 'Semester',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  // Disable if year is not selected
                                  items: _selectedYear == null
                                      ? []
                                      : _semesters
                                            .map(
                                              (sem) => DropdownMenuItem(
                                                value: sem,
                                                child: Text(sem),
                                              ),
                                            )
                                            .toList(),
                                  onChanged: _selectedYear == null
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedSemester = value;
                                          });
                                        },
                                  validator: (value) => value == null
                                      ? 'Please select semester'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Subject Name Input
                                TextFormField(
                                  controller: _subjectController,
                                  decoration: InputDecoration(
                                    labelText: 'Subject Full Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter subject name';
                                    }
                                    return null;
                                  },
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 16.0,
                ),
                child: Column(
                  children: [
                    Text(
                      'Only if you fill the faculty details you will be able to add students',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _submitDetails,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        label: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Settled',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        icon: _isLoading ? null : const Icon(Icons.check_circle_outline),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenteeDetailsPage extends StatefulWidget {
  const MenteeDetailsPage({super.key});

  @override
  State<MenteeDetailsPage> createState() => _MenteeDetailsPageState();
}

class _MenteeDetailsPageState extends State<MenteeDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();

  // Dropdown values
  String? _selectedBranch;
  String? _selectedYear;
  String? _selectedSemester;
  String? _selectedProjectType;

  // Team handling
  int _teamSize = 1;
  List<Map<String, String>> _allStudents = [];
  final List<Map<String, String>> _selectedStudents = [{}];

  bool _isLoading = false;

  final List<String> _branches = [
    'Information Technology',
    'Data Analytics',
    'Cyber Security',
  ];

  final List<String> _years = ['I', 'II'];

  final List<String> _projectTypes = ['Mini Project', 'Major Project'];

  List<String> get _semesters {
    if (_selectedYear == 'I') {
      return ['I', 'II'];
    } else if (_selectedYear == 'II') {
      return ['III', 'IV'];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _fetchAllStudents();
  }

  Future<void> _fetchAllStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('faculty_subjects')
          .where('facultyId', isEqualTo: user.uid)
          .get();

      List<Map<String, String>> tempStudents = [];

      for (var subjectDoc in subjectsSnapshot.docs) {
        final subjectData = subjectDoc.data();
        final String branch = subjectData['branch'] ?? '';

        final studentsSnapshot = await subjectDoc.reference
            .collection('students')
            .get();
        for (var studentDoc in studentsSnapshot.docs) {
          final data = studentDoc.data();
          tempStudents.add({
            'name': data['name'] ?? '',
            'rollNumber': data['rollNumber'] ?? '',
            'branch': branch,
            'display': '${data['name']} (${data['rollNumber']})',
          });
        }
      }

      if (mounted) {
        setState(() {
          _allStudents = tempStudents;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _projectNameController.clear();
    _batchController.clear();
    setState(() {
      _selectedBranch = null;
      _selectedYear = null;
      _selectedSemester = null;
      _selectedProjectType = null;
      _teamSize = 1;
      _selectedStudents.clear();
      _selectedStudents.add({});
    });
  }

  void _showMenteeDialog({String? docId, Map<String, dynamic>? data}) {
    // If editing, pre-fill data
    if (data != null) {
      _projectNameController.text = data['projectName'] ?? '';
      _batchController.text = data['batch'] ?? '';
      _selectedBranch = data['branch'];
      _selectedYear = data['year'];
      _selectedSemester = data['semester'];
      _selectedProjectType = data['projectType'];

      List<dynamic> savedStudents = data['students'] ?? [];
      _teamSize = savedStudents.isNotEmpty ? savedStudents.length : 1;
      _selectedStudents.clear();
      for (var s in savedStudents) {
        _selectedStudents.add(Map<String, String>.from(s));
      }
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                docId == null ? 'Add Mentee Details' : 'Edit Mentee Details',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Project Name
                      TextFormField(
                        controller: _projectNameController,
                        decoration: InputDecoration(
                          labelText: 'Project Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Branch Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedBranch,
                        decoration: InputDecoration(
                          labelText: 'Branch',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: _branches
                            .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBranch = val),
                        validator: (val) => val == null ? 'Required' : null,
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
                              (y) => DropdownMenuItem(value: y, child: Text(y)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() {
                          _selectedYear = val;
                          _selectedSemester = null;
                        }),
                        validator: (val) => val == null ? 'Required' : null,
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
                        items: _semesters
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: _selectedYear == null
                            ? null
                            : (val) => setState(() => _selectedSemester = val),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Batch Input
                      TextFormField(
                        controller: _batchController,
                        decoration: InputDecoration(
                          labelText: 'Batch (Start Year)',
                          hintText: 'e.g., 2023',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Project Type
                      DropdownButtonFormField<String>(
                        value: _selectedProjectType,
                        decoration: InputDecoration(
                          labelText: 'Project Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: _projectTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedProjectType = val),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Team Size
                      DropdownButtonFormField<int>(
                        value: _teamSize,
                        decoration: InputDecoration(
                          labelText: 'Team Size',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: [1, 2, 3, 4, 5]
                            .map(
                              (s) =>
                                  DropdownMenuItem(value: s, child: Text('$s')),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _teamSize = val;
                              if (_selectedStudents.length < val) {
                                for (
                                  int i = _selectedStudents.length;
                                  i < val;
                                  i++
                                ) {
                                  _selectedStudents.add({});
                                }
                              } else if (_selectedStudents.length > val) {
                                _selectedStudents.removeRange(
                                  val,
                                  _selectedStudents.length,
                                );
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Student Selectors
                      ...List.generate(_teamSize, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Autocomplete<Map<String, String>>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<
                                          Map<String, String>
                                        >.empty();
                                      }
                                      return _allStudents.where((student) {
                                        final matchesBranch =
                                            _selectedBranch == null ||
                                            student['branch'] ==
                                                _selectedBranch;
                                        final matchesQuery = student['display']!
                                            .toLowerCase()
                                            .contains(
                                              textEditingValue.text
                                                  .toLowerCase(),
                                            );
                                        return matchesBranch && matchesQuery;
                                      });
                                    },
                                displayStringForOption:
                                    (Map<String, String> option) =>
                                        option['display']!,
                                onSelected: (Map<String, String> selection) {
                                  _selectedStudents[index] = selection;
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      controller,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      if (_selectedStudents[index].isNotEmpty &&
                                          controller.text.isEmpty) {
                                        controller.text =
                                            _selectedStudents[index]['display']!;
                                      }
                                      return TextFormField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Search Name or Roll No',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          isDense: true,
                                        ),
                                        validator: (value) {
                                          if (_selectedStudents[index]
                                              .isEmpty) {
                                            return 'Please select a student';
                                          }
                                          return null;
                                        },
                                      );
                                    },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _saveMenteeDetails(docId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(docId == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveMenteeDetails(String? docId) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudents.any((s) => s.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select all students'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = {
        'facultyId': user.uid,
        'projectName': _projectNameController.text.trim(),
        'branch': _selectedBranch,
        'year': _selectedYear,
        'semester': _selectedSemester,
        'batch': _batchController.text.trim(),
        'projectType': _selectedProjectType,
        'students': _selectedStudents,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        if (docId == null) {
          data['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('mentee_details')
              .add(data);
        } else {
          await FirebaseFirestore.instance
              .collection('mentee_details')
              .doc(docId)
              .update(data);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(docId == null ? 'Mentee Added' : 'Mentee Updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Mentee Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenteeDialog(),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Mentee',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade900, Colors.indigo.shade500],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('mentee_details')
                .where(
                  'facultyId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No mentee details added yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final docs = snapshot.data!.docs.toList();
              // Client-side sorting to avoid Firestore index requirement
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white.withOpacity(0.95),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        data['projectName'] ?? 'Unknown Project',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data['branch'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data['projectType'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Batch: ${data['batch']} • ${data['year']} Year - Sem ${data['semester']}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          if (data['students'] != null &&
                              (data['students'] as List).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Team Members:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...((data['students'] as List).map(
                              (s) => Text(
                                '• ${s['name'] ?? ''} (${s['rollNumber'] ?? ''})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.indigo),
                            onPressed: () =>
                                _showMenteeDialog(docId: doc.id, data: data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(doc.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mentee Details?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('mentee_details')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mentee details deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

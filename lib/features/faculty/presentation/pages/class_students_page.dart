import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

class ClassStudentsPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String branch;
  final String year;
  final String semester;

  const ClassStudentsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.semester,
  });

  @override
  State<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends State<ClassStudentsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  Future<void> _importStudents() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        // Close the instructions dialog if open
        if (mounted) Navigator.pop(context);

        setState(() => _isLoading = true);

        final bytes = result.files.single.bytes;
        if (bytes == null) {
          throw Exception(
            'Could not read file data. Please use a valid .xlsx file.',
          );
        }

        var excel = Excel.decodeBytes(bytes);
        if (excel.tables.isEmpty)
          throw Exception('No sheets found in Excel file');

        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName];
        if (sheet == null) throw Exception('Sheet is empty');

        final collection = FirebaseFirestore.instance
            .collection('faculty_subjects')
            .doc(widget.subjectId)
            .collection('students');

        final batch = FirebaseFirestore.instance.batch();
        int count = 0;

        // Skip header row (start at 1)
        for (var i = 1; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row.length < 2) continue;

          final nameVal = row[0]?.value;
          final rollVal = row[1]?.value;

          if (nameVal == null || rollVal == null) continue;

          final name = nameVal.toString().trim();
          final roll = rollVal.toString().trim();

          if (name.isNotEmpty && roll.isNotEmpty) {
            final docRef = collection.doc();
            batch.set(docRef, {
              'name': name,
              'rollNumber': roll,
              'createdAt': FieldValue.serverTimestamp(),
            });
            count++;
          }
        }

        if (count > 0) {
          await batch.commit();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully imported $count students!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No valid data found. Ensure Col A=Name, Col B=RollNo.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Import failed: $e';
        if (e.toString().contains('LateInitializationError') ||
            e.toString().contains('_instance')) {
          errorMessage =
              'New features added. Please completely STOP and RESTART the app.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addStudent(
    String? docId, {
    Map<String, dynamic>? oldData,
  }) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final collection = FirebaseFirestore.instance
            .collection('faculty_subjects')
            .doc(widget.subjectId)
            .collection('students');

        if (docId == null) {
          await collection.add({
            'name': _nameController.text.trim(),
            'rollNumber': _rollNumberController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 1. Update the student in 'faculty_subjects'
          await collection.doc(docId).update({
            'name': _nameController.text.trim(),
            'rollNumber': _rollNumberController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // 2. Cascade update to 'mentee_details' if data changed
          if (oldData != null) {
            final oldName = oldData['name'];
            final oldRoll = oldData['rollNumber'];
            final newName = _nameController.text.trim();
            final newRoll = _rollNumberController.text.trim();

            if (oldName != newName || oldRoll != newRoll) {
              await _updateMenteeDetailsForStudent(
                oldName,
                oldRoll,
                newName,
                newRoll,
                docId,
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                docId == null
                    ? 'Student Added Successfully!'
                    : 'Student Updated Successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          if (docId == null) {
            _nameController.clear();
            _rollNumberController.clear();
          } else {
            Navigator.pop(context);
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

  Future<void> _updateMenteeDetailsForStudent(
    String oldName,
    String oldRoll,
    String newName,
    String newRoll,
    String studentId,
  ) async {
    // Note: This matches legacy records by Name/RollNo and new records by ID (if we stored it)
    // Currently, we'll traverse and match manually since `students` is an array of maps.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('mentee_details')
          .where('facultyId', isEqualTo: user.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      bool batchCommmitNeeded = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<dynamic> students = data['students'] ?? [];
        bool modified = false;
        List<Map<String, dynamic>> updatedStudents = [];

        for (var student in students) {
          Map<String, dynamic> studentMap = Map<String, dynamic>.from(student);

          bool match = false;
          // Match by ID if available (future proofing)
          if (studentMap.containsKey('id') && studentMap['id'] == studentId) {
            match = true;
          }
          // Match by Name and RollNo (legacy)
          else if (studentMap['name'] == oldName &&
              studentMap['rollNumber'] == oldRoll) {
            match = true;
          }

          if (match) {
            studentMap['name'] = newName;
            studentMap['rollNumber'] = newRoll;
            // Also update 'display' or other fields if you have them stored
            studentMap['display'] = '$newName ($newRoll)';
            modified = true;
          }
          updatedStudents.add(studentMap);
        }

        if (modified) {
          batch.update(doc.reference, {'students': updatedStudents});
          batchCommmitNeeded = true;
        }
      }

      if (batchCommmitNeeded) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error cascading update: $e');
    }
  }

  Future<void> _deleteStudent(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student?'),
        content: const Text('Are you sure you want to delete this student?'),
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
      if (!mounted) return;
      try {
        final docRef = FirebaseFirestore.instance
            .collection('faculty_subjects')
            .doc(widget.subjectId)
            .collection('students')
            .doc(docId);

        final docSnap = await docRef.get();
        String? name;
        String? rollNumber;
        if (docSnap.exists) {
          final data = docSnap.data();
          name = data?['name'];
          rollNumber = data?['rollNumber'];
        }

        await docRef.delete();

        if (name != null && rollNumber != null) {
          await _removeStudentFromMenteeDetails(docId, name, rollNumber);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student Deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAddOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showImportInstructionsDialog();
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Import from Excel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showStudentFormDialog();
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manual Entry'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showImportInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excel Import Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please ensure your Excel file (.xlsx) matches the following format:',
            ),
            const SizedBox(height: 16),
            const Text(
              '• Column A: Student Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '• Column B: Roll Number',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Notes:'),
            const Text('• The first row is treated as a header and skipped.'),
            const Text('• Empty rows will be ignored.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _importStudents,
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  void _showStudentFormDialog({String? docId, Map<String, dynamic>? data}) {
    if (docId != null && data != null) {
      _nameController.text = data['name'] ?? '';
      _rollNumberController.text = data['rollNumber'] ?? '';
    } else {
      _nameController.clear();
      _rollNumberController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? 'Add Student' : 'Edit Student'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rollNumberController,
                decoration: InputDecoration(
                  labelText: 'Roll No',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          StatefulBuilder(
            builder: (context, setState) {
              return ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await _addStudent(docId, oldData: data);
                        if (mounted && docId != null) {
                          // Dialog closed in _addStudent
                        } else if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(docId == null ? 'Add' : 'Update'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.branch} • Year ${widget.year} • Sem ${widget.semester}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptionsDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Student',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Student List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Enrolled Students',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Student List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('faculty_subjects')
                      .doc(widget.subjectId)
                      .collection('students')
                      .orderBy('rollNumber')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No students added yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white.withOpacity(0.9),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              data['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Roll No: ${data['rollNumber'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  onPressed: () => _showStudentFormDialog(
                                    docId: doc.id,
                                    data: data,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red,
                                  onPressed: () => _deleteStudent(doc.id),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeStudentFromMenteeDetails(
    String studentId,
    String name,
    String rollNumber,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('mentee_details')
          .where('facultyId', isEqualTo: user.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      bool batchWait = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<dynamic> students = data['students'] ?? [];
        final initialLength = students.length;

        final updatedStudents = students.where((s) {
          final map = s as Map<String, dynamic>;
          // Match logic: Remove if ID matches OR Name+Roll matches
          if (map['id'] == studentId) return false;
          if (map['name'] == name && map['rollNumber'] == rollNumber) {
            return false;
          }
          return true;
        }).toList();

        if (updatedStudents.length < initialLength) {
          batch.update(doc.reference, {'students': updatedStudents});
          batchWait = true;
        }
      }

      if (batchWait) await batch.commit();
    } catch (e) {
      debugPrint('Error removing student from mentees: $e');
    }
  }
}

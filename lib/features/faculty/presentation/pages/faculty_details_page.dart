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
            Navigator.pop(context); // Close the dialog
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

  void _showAddClassDialog() {
    // Reset form for new entry
    _subjectController.clear();
    setState(() {
      _selectedBranch = null;
      _selectedYear = null;
      _selectedSemester = null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Class & Subject'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        validator: (value) =>
                            value == null ? 'Please select a branch' : null,
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
                            _selectedSemester = null; // Reset semester
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select year' : null,
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
                        validator: (value) =>
                            value == null ? 'Please select semester' : null,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
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
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateClassDetails(String docId) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance
            .collection('faculty_subjects')
            .doc(docId)
            .update({
              'branch': _selectedBranch,
              'year': _selectedYear,
              'semester': _selectedSemester,
              'subjectName': _subjectController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject Updated Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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

  void _showEditClassDialog(String docId, Map<String, dynamic> data) {
    // Pre-fill form
    _subjectController.text = data['subjectName'] ?? '';
    setState(() {
      _selectedBranch = data['branch'];
      _selectedYear = data['year'];
      _selectedSemester = data['semester'];
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Class & Subject'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        validator: (value) =>
                            value == null ? 'Please select a branch' : null,
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
                            _selectedSemester = null; // Reset semester
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select year' : null,
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
                        validator: (value) =>
                            value == null ? 'Please select semester' : null,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _updateClassDetails(docId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
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
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteClass(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: const Text(
          'Are you sure you want to delete this subject? This action cannot be undone.',
        ),
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
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('faculty_subjects')
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject Deleted Successfully'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Class & Subject',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Your Classes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('faculty_subjects')
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
                      debugPrint('Error loading classes: ${snapshot.error}');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
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
                          'No classes added yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.toList();
                    // Sort locally to avoid Firestore index requirement
                    docs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTime = aData['createdAt'] as Timestamp?;
                      final bTime = bData['createdAt'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime); // Descending
                    });

                    return ListView.separated(
                      padding: const EdgeInsets.all(24.0),
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
                          color: Colors.white.withOpacity(0.9),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['subjectName'] ??
                                            'Unknown Subject',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '${data['branch']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _showEditClassDialog(
                                            doc.id,
                                            data,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _deleteClass(doc.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Year: ${data['year']}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.school_rounded,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sem: ${data['semester']}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
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
              Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 80.0, // Added padding for FAB
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
    );
  }
}

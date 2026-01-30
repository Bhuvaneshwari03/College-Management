import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectInternalsPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String branch;
  final String year;
  final String semester;

  const SubjectInternalsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.semester,
  });

  @override
  State<SubjectInternalsPage> createState() => _SubjectInternalsPageState();
}

class _SubjectInternalsPageState extends State<SubjectInternalsPage> {
  // Helper to format marks for display
  String _formatMark(dynamic value) {
    if (value == null) return '-';
    if (value == -1 || value == -1.0) return 'AB';
    return value.toString();
  }

  // Calculation Logic (Client Side for Display)
  double _calculateAverage(double i1, double i2, double i3) {
    // Treat -1 (Absent) as 0 for calculation purposes
    double v1 = (i1 == -1) ? 0 : i1;
    double v2 = (i2 == -1) ? 0 : i2;
    double v3 = (i3 == -1) ? 0 : i3;

    List<double> marks = [v1, v2, v3];
    marks.sort((a, b) => b.compareTo(a)); // Descending
    // Take top 2
    double sum = marks[0] + marks[1];
    return sum / 2;
  }

  Color _getMarkColor(dynamic value) {
    if (value == -1 || value == -1.0) return Colors.red;
    return Colors.black87;
  }

  void _showEditIdsDialog(
    String studentId,
    Map<String, dynamic> currentMarks,
    String studentName,
  ) {
    // Controllers
    // We use strings to handle "AB" logic if needed, or numeric input
    // Using -1 for AB.
    // UI: Checkbox for Absent?

    double? i1 = currentMarks['i1']?.toDouble();
    double? i2 = currentMarks['i2']?.toDouble();
    double? i3 = currentMarks['i3']?.toDouble();
    double? ass = currentMarks['ass']?.toDouble();
    double? sem = currentMarks['sem']?.toDouble();

    final i1Ctrl = TextEditingController(
      text: (i1 != null && i1 != -1) ? i1.toString() : '',
    );
    final i2Ctrl = TextEditingController(
      text: (i2 != null && i2 != -1) ? i2.toString() : '',
    );
    final i3Ctrl = TextEditingController(
      text: (i3 != null && i3 != -1) ? i3.toString() : '',
    );
    final assCtrl = TextEditingController(
      text: (ass != null) ? ass.toString() : '',
    );
    final semCtrl = TextEditingController(
      text: (sem != null) ? sem.toString() : '',
    );

    bool i1Abs = (i1 == -1);
    bool i2Abs = (i2 == -1);
    bool i3Abs = (i3 == -1);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Live calculation for preview
            double d1 = i1Abs ? 0 : (double.tryParse(i1Ctrl.text) ?? 0);
            double d2 = i2Abs ? 0 : (double.tryParse(i2Ctrl.text) ?? 0);
            double d3 = i3Abs ? 0 : (double.tryParse(i3Ctrl.text) ?? 0);
            double da = double.tryParse(assCtrl.text) ?? 0;
            double ds = double.tryParse(semCtrl.text) ?? 0;

            double avg = _calculateAverage(
              i1Abs ? -1 : d1,
              i2Abs ? -1 : d2,
              i3Abs ? -1 : d3,
            );
            double total = avg + da + ds;

            return AlertDialog(
              title: Text('Update Marks: $studentName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Internal 1
                    _buildMarkInput(
                      'Internal 1 (25)',
                      i1Ctrl,
                      i1Abs,
                      (val) => setState(() => i1Abs = val),
                      25,
                    ),
                    const SizedBox(height: 12),
                    // Internal 2
                    _buildMarkInput(
                      'Internal 2 (25)',
                      i2Ctrl,
                      i2Abs,
                      (val) => setState(() => i2Abs = val),
                      25,
                    ),
                    const SizedBox(height: 12),
                    // Internal 3
                    _buildMarkInput(
                      'Internal 3 (25)',
                      i3Ctrl,
                      i3Abs,
                      (val) => setState(() => i3Abs = val),
                      25,
                    ),
                    const Divider(height: 24),
                    // Assessment
                    TextFormField(
                      controller: assCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Assessment (5)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    // Seminar
                    TextFormField(
                      controller: semCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Seminar (5)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    // Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Avg (Best 2)',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                avg.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                total.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Logic to save
                    final m1 = i1Abs ? -1.0 : double.tryParse(i1Ctrl.text);
                    final m2 = i2Abs ? -1.0 : double.tryParse(i2Ctrl.text);
                    final m3 = i3Abs ? -1.0 : double.tryParse(i3Ctrl.text);
                    final ma = double.tryParse(assCtrl.text);
                    final ms = double.tryParse(semCtrl.text);

                    // Validation?
                    // if (m1 != null && m1 > 25 && m1 != -1) return error;

                    final marksMap = {
                      'i1': m1,
                      'i2': m2,
                      'i3': m3,
                      'ass': ma,
                      'sem': ms,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    await FirebaseFirestore.instance
                        .collection('faculty_subjects')
                        .doc(widget.subjectId)
                        .collection('students')
                        .doc(studentId)
                        .update({'internalMarks': marksMap});

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marks Updated'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMarkInput(
    String label,
    TextEditingController controller,
    bool isAbsent,
    Function(bool) onAbsChanged,
    double max,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: !isAbsent,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              errorText: (double.tryParse(controller.text) ?? 0) > max
                  ? 'Max $max'
                  : null,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            Checkbox(
              value: isAbsent,
              activeColor: Colors.red,
              onChanged: (val) {
                onAbsChanged(val ?? false);
                if (val == true) controller.clear();
              },
            ),
            const Text(
              'AB',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.branch} • ${widget.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('faculty_subjects')
            .doc(widget.subjectId)
            .collection('students')
            .orderBy('rollNumber')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No students found. Add students in "Add Student" or "Class Students" page.',
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(
                  Colors.grey.shade200,
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Roll No',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Int 1\n(25)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Int 2\n(25)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Int 3\n(25)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Avg\n(Best 2)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Ass\n(5)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Sem\n(5)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Action',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final marks =
                      data['internalMarks'] as Map<String, dynamic>? ?? {};

                  double? i1 = marks['i1']?.toDouble();
                  double? i2 = marks['i2']?.toDouble();
                  double? i3 = marks['i3']?.toDouble();
                  double? ass = marks['ass']?.toDouble();
                  double? sem = marks['sem']?.toDouble();

                  double avg = _calculateAverage(i1 ?? 0, i2 ?? 0, i3 ?? 0);
                  double total = avg + (ass ?? 0) + (sem ?? 0);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          data['rollNumber'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(data['name'] ?? 'Unknown')),
                      // Internals
                      DataCell(
                        Text(
                          _formatMark(i1),
                          style: TextStyle(
                            color: _getMarkColor(i1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatMark(i2),
                          style: TextStyle(
                            color: _getMarkColor(i2),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatMark(i3),
                          style: TextStyle(
                            color: _getMarkColor(i3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Average
                      DataCell(
                        Text(
                          avg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      // Ass & Sem
                      DataCell(Text(_formatMark(ass))),
                      DataCell(Text(_formatMark(sem))),
                      // Total
                      DataCell(
                        Text(
                          total.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () =>
                              _showEditIdsDialog(doc.id, marks, data['name']),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

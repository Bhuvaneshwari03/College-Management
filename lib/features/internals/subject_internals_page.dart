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
  // We always want to convert internal marks (out of 25) to 15 for display in the table
  String _formatMark(dynamic value, {bool isInternalMark = false}) {
    if (value == null) return '-';
    if (value == -1 || value == -1.0) return 'AB';

    double val = value is int ? value.toDouble() : value;

    // If it's an internal mark (out of 25), convert to 15 for display
    if (isInternalMark && val != -1) {
      val = val * 0.6; // Convert 25 to 15
      if (val % 1 == 0) return val.toInt().toString();
      return val.toStringAsFixed(1);
    }

    return val % 1 == 0 ? val.toInt().toString() : val.toString();
  }

  // Calculation Logic (Client Side for Display)
  double? _calculateAverage(double? i1, double? i2, double? i3) {
    if (i1 == null || i2 == null || i3 == null) return null;

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

  void _showEditStudentDialog(
    List<QueryDocumentSnapshot> allDocs,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        int currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (context, setState) {
            final doc = allDocs[currentIndex];
            final data = doc.data() as Map<String, dynamic>;
            final currentMarks =
                data['internalMarks'] as Map<String, dynamic>? ?? {};
            final studentName = data['name'] ?? 'Unknown';

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

            return AlertDialog(
              title: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Update Marks',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${currentIndex + 1}/${allDocs.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter marks out of 25',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMarkInput('Internal 1 (25)', i1Ctrl, i1Abs, (val) {
                      setState(() {
                        i1Abs = val;
                      });
                    }, 25),
                    const SizedBox(height: 12),
                    _buildMarkInput('Internal 2 (25)', i2Ctrl, i2Abs, (val) {
                      setState(() {
                        i2Abs = val;
                      });
                    }, 25),
                    const SizedBox(height: 12),
                    _buildMarkInput('Internal 3 (25)', i3Ctrl, i3Abs, (val) {
                      setState(() {
                        i3Abs = val;
                      });
                    }, 25),
                    const Divider(height: 24),
                    TextFormField(
                      controller: assCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Assessment (5)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: semCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Seminar (5)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentIndex > 0
                              ? () => setState(() => currentIndex--)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentIndex < allDocs.length - 1
                              ? () => setState(() => currentIndex++)
                              : null,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final m1 = i1Abs
                                ? -1.0
                                : double.tryParse(i1Ctrl.text);
                            final m2 = i2Abs
                                ? -1.0
                                : double.tryParse(i2Ctrl.text);
                            final m3 = i3Abs
                                ? -1.0
                                : double.tryParse(i3Ctrl.text);
                            final ma = double.tryParse(assCtrl.text);
                            final ms = double.tryParse(semCtrl.text);

                            // Validation
                            if ((m1 != null && m1 > 25) ||
                                (m2 != null && m2 > 25) ||
                                (m3 != null && m3 > 25) ||
                                (ma != null && ma > 5) ||
                                (ms != null && ms > 5)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Marks cannot exceed limit (25 for Int, 5 for Ass/Sem)',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

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
                                .doc(doc.id)
                                .update({'internalMarks': marksMap});

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marks Updated'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(milliseconds: 800),
                                ),
                              );
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              '${widget.branch} • ${widget.year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
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
                'No students found. Add students in "Add Student" page.',
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      border: TableBorder.all(
                        color: Colors.black54,
                        width: 1,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      columnSpacing: 20,
                      headingRowColor: MaterialStateProperty.all(
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      ),
                      columns: [
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
                            'Int 1\n(15)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Int 2\n(15)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Int 3\n(15)',
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
                              color: Theme.of(context).colorScheme.secondary,
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
                              color: Theme.of(context).colorScheme.primary,
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
                      rows: docs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        final data = doc.data() as Map<String, dynamic>;
                        final marks =
                            data['internalMarks'] as Map<String, dynamic>? ??
                            {};

                        double? i1 = marks['i1']?.toDouble();
                        double? i2 = marks['i2']?.toDouble();
                        double? i3 = marks['i3']?.toDouble();
                        double? ass = marks['ass']?.toDouble();
                        double? sem = marks['sem']?.toDouble();

                        // Avg calculation (on original marks)
                        // Returns null if any internal is missing
                        double? avg = _calculateAverage(i1, i2, i3);

                        // Convert Avg to 15 if valid
                        if (avg != null) {
                          avg = avg * 0.6;
                        }

                        // Total calculation
                        // calculated only if avg, ass, and sem are all present
                        double? total;
                        if (avg != null && ass != null && sem != null) {
                          total = avg + ass + sem;
                        }

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                data['rollNumber'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(data['name'] ?? 'Unknown')),
                            // Internals - displayed out of 15
                            DataCell(
                              Text(
                                _formatMark(i1, isInternalMark: true),
                                style: TextStyle(
                                  color: _getMarkColor(i1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatMark(i2, isInternalMark: true),
                                style: TextStyle(
                                  color: _getMarkColor(i2),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatMark(i3, isInternalMark: true),
                                style: TextStyle(
                                  color: _getMarkColor(i3),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Average - displayed out of 15
                            DataCell(
                              Text(
                                avg != null ? avg.toStringAsFixed(1) : '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: avg != null
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            // Ass & Sem
                            DataCell(Text(_formatMark(ass))),
                            DataCell(Text(_formatMark(sem))),
                            // Total
                            DataCell(
                              Text(
                                total != null ? total.toStringAsFixed(1) : '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: total != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                onPressed: () =>
                                    _showEditStudentDialog(docs, index),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

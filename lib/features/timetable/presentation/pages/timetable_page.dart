import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final List<String> _periods = [
    '10:00 - 11:00\n(1st)',
    '11:00 - 12:00\n(2nd)',
    '12:00 - 12:15',
    '12:15 - 01:15\n(3rd)',
    '01:15 - 02:00',
    '02:00 - 03:00\n(4th)',
    '03:00 - 04:00\n(5th)',
    '04:00 - 05:00\n(6th)',
  ];

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  bool _isEditing = false;
  Map<String, dynamic> _localTimetable = {};
  Map<String, dynamic> _dbData = {};

  Future<void> _showSessionDialog(
    BuildContext context,
    String day,
    int periodIndex,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Session for $day - Period ${periodIndex + 1}'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('faculty_subjects')
                  .where('facultyId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final docs = snapshot.data?.docs ?? [];

                return ListView(
                  shrinkWrap: true,
                  children: [
                    if (docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'No subjects found. Add subjects in Faculty Details.',
                        ),
                      ),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final subjectName = data['subjectName'] ?? 'Unknown';
                      final branch = data['branch'] ?? '';
                      final year = data['year'] ?? '';
                      final displayString = '$subjectName ($branch - $year)';

                      return ListTile(
                        title: Text(
                          subjectName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$branch • $year'),
                        onTap: () => _updateLocalTimetable(
                          day,
                          periodIndex,
                          displayString,
                        ),
                      );
                    }),
                    ListTile(
                      title: const Text(
                        'Free Period',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _updateLocalTimetable(
                        day,
                        periodIndex,
                        'Free Period',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _updateLocalTimetable(String day, int periodIndex, String value) {
    Navigator.pop(context); // Close dialog
    setState(() {
      if (!_localTimetable.containsKey(day)) {
        _localTimetable[day] = <String, dynamic>{};
      } else if (_localTimetable[day] is! Map<String, dynamic>) {
        // Ensure it's the correct type if it exists but is generic
        _localTimetable[day] = Map<String, dynamic>.from(
          _localTimetable[day] as Map,
        );
      }
      _localTimetable[day][periodIndex.toString()] = value;
    });
  }

  Future<void> _saveTimetable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('faculty_timetables')
          .doc(user.uid)
          .set(_localTimetable); // Overwrite with local state

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving timetable: $e')));
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancel editing
        _isEditing = false;
      } else {
        // Start editing, create deep copy of dbData
        _localTimetable = {};
        _dbData.forEach((key, value) {
          if (value is Map) {
            _localTimetable[key] = Map<String, dynamic>.from(value);
          }
        });
        _isEditing = true;
      }
    });
  }

  Color _getSubjectColor(String subject) {
    if (subject == '-' || subject.isEmpty) return Colors.transparent;

    // Custom premium mild colors
    final List<Color> colors = [
      const Color(0xFFE3F2FD), // Mild Blue
      const Color(0xFFF3E5F5), // Mild Purple
      const Color(0xFFE8F5E9), // Mild Green
      const Color(0xFFFFF3E0), // Mild Orange
      const Color(0xFFFCE4EC), // Mild Pink
      const Color(0xFFE0F7FA), // Mild Cyan
    ];

    if (subject == 'Free Period') {
      return const Color(0xFFFFF9C4); // Mild Yellow for Free Period
    }

    return colors[subject.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: Colors.deepPurple.withOpacity(0.2),
      width: 1,
    );
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Timetable',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isEditing) {
              // Prompt to discard changes? For now just pop
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: _isEditing ? _saveTimetable : _toggleEdit,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade500],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance
                      .collection('faculty_timetables')
                      .doc(user.uid)
                      .snapshots()
                : null,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data();
                if (data is Map) {
                  _dbData = Map<String, dynamic>.from(data);
                } else {
                  _dbData = {};
                }
              } else {
                _dbData = {};
              }

              // Use local data if editing, otherwise live DB data
              final displayData = _isEditing ? _localTimetable : _dbData;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.deepPurple.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            // Clip is needed to ensure children respect the rounded corners
                            clipBehavior: Clip.antiAlias,
                            child: Table(
                              defaultColumnWidth: const FixedColumnWidth(150.0),
                              // No global table border logic; we handle it manually per cell
                              border: null,
                              children: [
                                // Header Row (Time Slots)
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                  ),
                                  children: [
                                    TableCell(
                                      verticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: borderSide,
                                            bottom: borderSide,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.all(8.0),
                                        child: const Text(
                                          'Day / Time',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ..._periods.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final period = entry.value;
                                      // Last header cell doesn't need right border if avoiding double borders,
                                      // but simplest consistency is keep it. The wrapper border handles the outside edge.
                                      return TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: borderSide,
                                              bottom: borderSide,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            period,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                // Data Rows (Days)
                                ..._days.map((day) {
                                  final isLastRow = day == _days.last;
                                  final dayData =
                                      displayData[day]
                                          as Map<String, dynamic>? ??
                                      {};

                                  return TableRow(
                                    children: [
                                      // Day Column
                                      TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.fill,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple
                                                .withOpacity(0.05),
                                            border: Border(
                                              right: borderSide,
                                              // Only draw bottom border if not the last row
                                              bottom: isLastRow
                                                  ? BorderSide.none
                                                  : borderSide,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            day,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Period Cells
                                      ...List.generate(_periods.length, (
                                        index,
                                      ) {
                                        // Index 2 is Interval, Index 4 is Lunch
                                        final isBreak =
                                            index == 2 || index == 4;
                                        if (isBreak) {
                                          // Only show text in the middle row (Wednesday, index 2)
                                          final showText =
                                              _days.indexOf(day) == 2;
                                          return TableCell(
                                            verticalAlignment:
                                                TableCellVerticalAlignment.fill,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(
                                                  0.2,
                                                ),
                                                // Break cells ONLY have a right border.
                                                // NO bottom border to creating specific merging.
                                                border: Border(
                                                  right: borderSide,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: showText
                                                  ? OverflowBox(
                                                      minHeight: 0.0,
                                                      maxHeight:
                                                          double.infinity,
                                                      child: RotatedBox(
                                                        quarterTurns: 3,
                                                        child: Text(
                                                          index == 2
                                                              ? 'INTERVAL'
                                                              : 'LUNCH',
                                                          softWrap: false,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .grey
                                                                .shade700,
                                                            letterSpacing: 2.0,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          );
                                        }

                                        final uniqueSubject =
                                            dayData[index.toString()] ?? '-';
                                        final cellColor = _getSubjectColor(
                                          uniqueSubject,
                                        );

                                        return TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: InkWell(
                                            onTap: _isEditing
                                                ? () => _showSessionDialog(
                                                    context,
                                                    day,
                                                    index,
                                                  )
                                                : null,
                                            child: Container(
                                              height:
                                                  100, // Fixed height for cells
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: borderSide,
                                                  bottom: isLastRow
                                                      ? BorderSide.none
                                                      : borderSide,
                                                ),
                                                // If subject exists, use its color.
                                                // If subject is '-', use white if editing (to encourage click), else transparent.
                                                color: uniqueSubject != '-'
                                                    ? cellColor
                                                    : (_isEditing
                                                          ? Colors.white
                                                          : Colors.transparent),
                                              ),
                                              child: Text(
                                                uniqueSubject,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      uniqueSubject != '-'
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color:
                                                      _isEditing &&
                                                          uniqueSubject == '-'
                                                      ? Colors.grey.shade400
                                                      : Colors.black,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    const Padding(
                      padding: EdgeInsets.only(
                        bottom: 24.0,
                        top: 8.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: Text(
                        'Editing Mode: Click on a session to change it. Don\'t forget to Save.',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(
                        bottom: 24.0,
                        top: 8.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: Text(
                        'Click Edit button to modify timetable.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  // Mock data for the timetable
  final List<String> _timeSlots = [
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 11:15', // Break
    '11:15 - 12:15',
    '12:15 - 01:15',
    '01:15 - 02:00', // Lunch
    '02:00 - 03:00',
    '03:00 - 04:00',
  ];

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  final Map<String, Map<String, String>> _timetableData = {
    // Example data structure: 'Mon': {'09:00 - 10:00': 'Subject A'}
  };

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
        ),
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white.withOpacity(0.95),
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: MaterialStateProperty.all(
                            Colors.deepPurple.withOpacity(0.1),
                          ),
                          columns: [
                            const DataColumn(
                              label: Text(
                                'Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            ..._days.map(
                              (day) => DataColumn(
                                label: Text(
                                  day,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: _timeSlots.map((time) {
                            final isBreakOrLunch =
                                time.contains('11:00') ||
                                time.contains('01:15');
                            return DataRow(
                              color: isBreakOrLunch
                                  ? MaterialStateProperty.all(
                                      Colors.grey.withOpacity(0.2),
                                    )
                                  : null,
                              cells: [
                                DataCell(
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                ..._days.map((day) {
                                  if (isBreakOrLunch) {
                                    return DataCell(
                                      Text(
                                        time.contains('11:00')
                                            ? 'BREAK'
                                            : 'LUNCH',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }
                                  return DataCell(
                                    Container(
                                      alignment: Alignment.center,
                                      width: 80,
                                      child: Text(
                                        _timetableData[day]?[time] ?? '-',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    onTap: () {
                                      // TODO: Implement edit/add subject logic
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Clicked $day at $time',
                                          ),
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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

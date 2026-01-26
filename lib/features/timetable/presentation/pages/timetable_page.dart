import 'package:flutter/material.dart';

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

  final Map<String, Map<int, String>> _timetableData = {
    'Mon': {},
    'Tue': {},
    'Wed': {},
    'Thu': {},
    'Fri': {},
  };

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: Colors.deepPurple.withOpacity(0.2),
      width: 1,
    );

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
                          defaultColumnWidth: const FixedColumnWidth(100.0),
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
                              return TableRow(
                                children: [
                                  // Day Column
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.fill,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.withOpacity(
                                          0.05,
                                        ),
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
                                  ...List.generate(_periods.length, (index) {
                                    // Index 2 is Interval, Index 4 is Lunch
                                    final isBreak = index == 2 || index == 4;
                                    if (isBreak) {
                                      // Only show text in the middle row (Wednesday, index 2)
                                      final showText = _days.indexOf(day) == 2;
                                      return TableCell(
                                        verticalAlignment:
                                            TableCellVerticalAlignment.fill,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.2),
                                            // Break cells ONLY have a right border.
                                            // NO bottom border to creating specific merging.
                                            border: Border(right: borderSide),
                                          ),
                                          alignment: Alignment.center,
                                          child: showText
                                              ? OverflowBox(
                                                  minHeight: 0.0,
                                                  maxHeight: double.infinity,
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
                                    return TableCell(
                                      verticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      child: InkWell(
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Clicked $day Period ${index + 1}',
                                              ),
                                              duration: const Duration(
                                                milliseconds: 500,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 60, // Fixed height for cells
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: borderSide,
                                              bottom: isLastRow
                                                  ? BorderSide.none
                                                  : borderSide,
                                            ),
                                          ),
                                          child: Text(
                                            (_timetableData[day] ??
                                                    {})[index] ??
                                                '-',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
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
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MonthlyAttendancePage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String branch;
  final String year;
  final String semester;

  const MonthlyAttendancePage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.semester,
  });

  @override
  State<MonthlyAttendancePage> createState() => _MonthlyAttendancePageState();
}

class _MonthlyAttendancePageState extends State<MonthlyAttendancePage> {
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reportData = [];
  int _daysInMonth = 30;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _selectMonth(BuildContext context) async {
    // Simple month picker using showDatePicker but limiting selection?
    // Or just a year/month picker.
    // For MVP, letting them pick a date and we use its month.
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'SELECT MONTH',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _isLoading = true;
      });
      _fetchReportData();
    }
  }

  int _getDaysInMonth(DateTime date) {
    return DateUtils.getDaysInMonth(date.year, date.month);
  }

  Future<void> _fetchReportData() async {
    try {
      _daysInMonth = _getDaysInMonth(_selectedMonth);
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('faculty_subjects')
          .doc(widget.subjectId)
          .collection('students')
          .orderBy('rollNumber')
          .get();

      List<Map<String, dynamic>> compiledData = [];

      // This could be optimized, but ok for class size < 100
      for (var doc in studentsSnapshot.docs) {
        final studentData = doc.data();
        final studentName = studentData['name'] ?? 'Unknown';
        final rollNumber = studentData['rollNumber'] ?? 'N/A';

        // Fetch attendance for this student
        final attendanceSnapshot = await doc.reference
            .collection('attendance')
            .get();

        Map<int, bool> realAttendance = {}; // What is in DB

        for (var attDoc in attendanceSnapshot.docs) {
          final dateId = attDoc.id; // YYYY-MM-DD
          try {
            final dateParts = dateId.split('-');
            final year = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final day = int.parse(dateParts[2]);

            if (year == _selectedMonth.year && month == _selectedMonth.month) {
              realAttendance[day] = attDoc.data()['present'] == true;
            }
          } catch (e) {
            // Ignore badly formatted dates
          }
        }

        // Calculate derived status and total
        Map<int, bool> dailyStatus = {};
        int presentCount = 0;
        final now = DateTime.now();
        // Reset time to midnight for fair comparison
        final today = DateTime(now.year, now.month, now.day);

        for (int day = 1; day <= _daysInMonth; day++) {
          final dateToCheck = DateTime(
            _selectedMonth.year,
            _selectedMonth.month,
            day,
          );

          if (realAttendance.containsKey(day)) {
            final isPresent = realAttendance[day]!;
            dailyStatus[day] = isPresent;
            if (isPresent) presentCount++;
          } else {
            // No record.
            if (dateToCheck.isAfter(today)) {
              // Future: show nothing
            } else {
              // Past/Today: Implicitly Present
              dailyStatus[day] = true;
              presentCount++;
            }
          }
        }

        compiledData.add({
          'name': studentName,
          'rollNumber': rollNumber,
          'dailyStatus': dailyStatus,
          'presentCount': presentCount,
        });
      }

      if (mounted) {
        setState(() {
          _reportData = compiledData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${DateFormat('MMMM yyyy').format(_selectedMonth)} • ${widget.subjectName}',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            tooltip: 'Select Month',
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _reportData.isEmpty
              ? const Center(
                  child: Text(
                    'No students found.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                ),
                                columnSpacing: 20,
                                border: TableBorder.all(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                                columns: [
                                  const DataColumn(
                                    label: Text(
                                      'S.No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(
                                      'Roll No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(
                                      'Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(_daysInMonth, (index) {
                                    return DataColumn(
                                      label: Container(
                                        alignment: Alignment.center,
                                        width: 20,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  const DataColumn(
                                    label: Text(
                                      'Total',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _reportData.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final data = entry.value;
                                  final dailyStatus =
                                      data['dailyStatus'] as Map<int, bool>;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${index + 1}')),
                                      DataCell(
                                        Text(data['rollNumber'].toString()),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 120, // fixed width for name
                                          child: Text(
                                            data['name'].toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      ...List.generate(_daysInMonth, (index) {
                                        final day = index + 1;
                                        final status = dailyStatus[day];
                                        return DataCell(
                                          Container(
                                            alignment: Alignment.center,
                                            child: status == null
                                                ? const Text(
                                                    '-',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                : Icon(
                                                    status
                                                        ? Icons.check_circle
                                                        : Icons.cancel,
                                                    size: 16,
                                                    color: status
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                          ),
                                        );
                                      }),
                                      DataCell(
                                        Text(
                                          data['presentCount'].toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
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

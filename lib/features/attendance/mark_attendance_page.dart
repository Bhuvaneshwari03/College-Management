import 'package:flutter/material.dart';
import 'package:college_management/features/attendance/attendance_model.dart';
import 'package:college_management/features/attendance/attendance_service.dart';

class MarkAttendancePage extends StatefulWidget {
  final StudentModel student;

  const MarkAttendancePage({super.key, required this.student});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final _attendanceService = AttendanceService();
  DateTime _selectedDate = DateTime.now();
  bool _isPresent = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceStatus();
  }

  Future<void> _fetchAttendanceStatus() async {
    setState(() => _isLoading = true);
    final status = await _attendanceService.getAttendanceStatus(
      widget.student.id,
      _selectedDate,
    );
    if (mounted) {
      setState(() {
        _isPresent = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAttendance(bool value) async {
    setState(() => _isPresent = value);
    try {
      await _attendanceService.markAttendance(
        widget.student.id,
        _selectedDate,
        value,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marked as ${value ? "Present" : "Absent"} for ${_selectedDate.toLocal().toString().split(' ')[0]}',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: value ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPresent = !value); // Revert on error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchAttendanceStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.student.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.person,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.student.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.student.department} • ${widget.student.studentClass}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Change Date'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Transform.scale(
                scale: 1.5,
                child: SwitchListTile(
                  title: Text(
                    _isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      color: _isPresent ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  value: _isPresent,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red[100],
                  onChanged: (bool value) {
                    _updateAttendance(value);
                  },
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Toggle to mark attendance',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

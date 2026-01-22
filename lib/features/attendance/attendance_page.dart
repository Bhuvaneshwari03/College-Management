import 'package:flutter/material.dart';
import 'package:college_management/features/attendance/add_student_page.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: const Center(
        child: Text(
          'Students List Coming Soon',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentPage()),
          );
        },
        label: const Text('Add Student'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

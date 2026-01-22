import 'package:flutter/material.dart';
import 'package:college_management/features/attendance/attendance_model.dart';
import 'package:college_management/features/attendance/attendance_service.dart';
import 'package:college_management/features/attendance/mark_attendance_page.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student List')),
      body: StreamBuilder<List<StudentModel>>(
        stream: AttendanceService().getStudents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No students found.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final student = snapshot.data![index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple[100],
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${student.department} • ${student.studentClass}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MarkAttendancePage(student: student),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

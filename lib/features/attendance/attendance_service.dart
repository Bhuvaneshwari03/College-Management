import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_management/features/attendance/attendance_model.dart';

class AttendanceService {
  final CollectionReference _studentsCollection = FirebaseFirestore.instance
      .collection('students');

  Future<void> addStudent(StudentModel student) async {
    try {
      // We don't use student.id here because Firestore auto-generates it for new documents
      // if using .add(), but strict requirement says studentId is auto.
      // We will pass the data without ID to .add()
      await _studentsCollection.add(student.toMap());
    } catch (e) {
      throw Exception('Failed to add student: $e');
    }
  }

  // Future methods for attendance marking will go here
}

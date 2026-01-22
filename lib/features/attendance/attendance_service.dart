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

  Stream<List<StudentModel>> getStudents() {
    return _studentsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> markAttendance(
    String studentId,
    DateTime date,
    bool present,
  ) async {
    try {
      final docId = date.toIso8601String().split(
        'T',
      )[0]; // Use YYYY-MM-DD as ID
      await _studentsCollection
          .doc(studentId)
          .collection('attendance')
          .doc(docId)
          .set({'date': date.toIso8601String(), 'present': present});
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  Future<bool> getAttendanceStatus(String studentId, DateTime date) async {
    try {
      final docId = date.toIso8601String().split('T')[0];
      final doc = await _studentsCollection
          .doc(studentId)
          .collection('attendance')
          .doc(docId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['present'] as bool;
      }
      return true; // Default to present as per requirement
    } catch (e) {
      return true; // Default error state
    }
  }
}

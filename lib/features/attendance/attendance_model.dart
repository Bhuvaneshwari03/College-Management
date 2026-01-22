import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String department;
  final String studentClass;
  final String batch;
  final DateTime? createdAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.department,
    required this.studentClass,
    required this.batch,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'department': department,
      'class': studentClass,
      'batch': batch,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, String docId) {
    return StudentModel(
      id: docId,
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      studentClass: map['class'] ?? '',
      batch: map['batch'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class AttendanceRecordModel {
  final String id; // dateId
  final DateTime date;
  final bool present;

  AttendanceRecordModel({
    required this.id,
    required this.date,
    required this.present,
  });

  Map<String, dynamic> toMap() {
    return {'date': date.toIso8601String(), 'present': present};
  }

  factory AttendanceRecordModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return AttendanceRecordModel(
      id: docId,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      present: map['present'] ?? false,
    );
  }
}

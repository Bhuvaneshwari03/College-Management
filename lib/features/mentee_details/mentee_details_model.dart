class MenteeDetailsModel {
  final String id; // studentId
  final String studentName;
  final String projectName;
  final String guideName;
  final String department;
  final String batch;
  final String type; // mini/major

  MenteeDetailsModel({
    required this.id,
    required this.studentName,
    required this.projectName,
    required this.guideName,
    required this.department,
    required this.batch,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentName': studentName,
      'projectName': projectName,
      'guideName': guideName,
      'department': department,
      'batch': batch,
      'type': type,
    };
  }

  factory MenteeDetailsModel.fromMap(Map<String, dynamic> map, String docId) {
    return MenteeDetailsModel(
      id: docId,
      studentName: map['studentName'] ?? '',
      projectName: map['projectName'] ?? '',
      guideName: map['guideName'] ?? '',
      department: map['department'] ?? '',
      batch: map['batch'] ?? '',
      type: map['type'] ?? '',
    );
  }
}

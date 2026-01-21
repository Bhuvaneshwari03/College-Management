class ProjectModel {
  final String id; // studentId
  final String studentName;
  final String projectName;
  final String guideName;
  final String department;
  final String batch;
  final String type; // mini/major

  ProjectModel({
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

  factory ProjectModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProjectModel(
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

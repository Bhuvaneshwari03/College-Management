class InternalMarksModel {
  final String id; // studentId
  final String studentName;
  final double internal1;
  final double internal2;
  final double internal3;
  final double average;
  final double assessment;
  final double seminar;

  InternalMarksModel({
    required this.id,
    required this.studentName,
    required this.internal1,
    required this.internal2,
    required this.internal3,
    required this.average,
    required this.assessment,
    required this.seminar,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentName': studentName,
      'internal1': internal1,
      'internal2': internal2,
      'internal3': internal3,
      'average': average,
      'assessment': assessment,
      'seminar': seminar,
    };
  }

  factory InternalMarksModel.fromMap(Map<String, dynamic> map, String docId) {
    return InternalMarksModel(
      id: docId,
      studentName: map['studentName'] ?? '',
      internal1: (map['internal1'] ?? 0).toDouble(),
      internal2: (map['internal2'] ?? 0).toDouble(),
      internal3: (map['internal3'] ?? 0).toDouble(),
      average: (map['average'] ?? 0).toDouble(),
      assessment: (map['assessment'] ?? 0).toDouble(),
      seminar: (map['seminar'] ?? 0).toDouble(),
    );
  }
}

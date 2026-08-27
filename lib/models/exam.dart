/// 考试安排
class Exam {
  String id;
  String courseName; // 对应课程名称
  String examName; // 考试名称（期中/期末/补考等）
  DateTime dateTime; // 考试时间
  String location; // 考场
  String remark; // 备注
  bool remind; // 是否提醒

  Exam({
    String? id,
    required this.courseName,
    this.examName = '',
    required this.dateTime,
    this.location = '',
    this.remark = '',
    this.remind = true,
  }) : id = id ?? uuid();

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseName': courseName,
        'examName': examName,
        'dateTime': dateTime.toIso8601String(),
        'location': location,
        'remark': remark,
        'remind': remind,
      };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'],
        courseName: json['courseName'],
        examName: json['examName'] ?? '',
        dateTime: DateTime.parse(json['dateTime']),
        location: json['location'] ?? '',
        remark: json['remark'] ?? '',
        remind: json['remind'] ?? true,
      );
}

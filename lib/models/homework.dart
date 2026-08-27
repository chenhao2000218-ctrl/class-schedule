import 'course.dart';

/// 作业待办
class Homework {
  String id;
  String courseId; // 绑定的课程ID
  String title; // 作业标题
  String content; // 作业内容
  DateTime? deadline; // 截止时间
  bool completed; // 是否完成
  DateTime createdAt;

  Homework({
    String? id,
    required this.courseId,
    required this.title,
    this.content = '',
    this.deadline,
    this.completed = false,
    DateTime? createdAt,
  })  : id = id ?? uuid(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'content': content,
        'deadline': deadline?.toIso8601String(),
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json['id'],
        courseId: json['courseId'],
        title: json['title'],
        content: json['content'] ?? '',
        deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
        completed: json['completed'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}

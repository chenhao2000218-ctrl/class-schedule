import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/exam.dart';
import '../utils/date_utils.dart';

/// 考试安排页面
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final exams = List.from(state.exams)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(title: const Text('考试安排')),
      body: exams.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无考试安排', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exams.length,
              itemBuilder: (ctx, i) {
                final exam = exams[i];
                final isPast = exam.dateTime.isBefore(DateTime.now());
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPast
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${exam.dateTime.day}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      exam.courseName,
                      style: TextStyle(
                        decoration:
                            isPast ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      '${exam.examName.isNotEmpty ? exam.examName + ' · ' : ''}'
                      '${DateUtils.formatDateTime(exam.dateTime)}'
                      '${exam.location.isNotEmpty ? ' · ${exam.location}' : ''}',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        const PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') _editExam(exam);
                        if (v == 'delete') state.deleteExam(exam.id);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExam,
        icon: const Icon(Icons.add),
        label: const Text('添加考试'),
      ),
    );
  }

  Future<void> _addExam() async {
    final result = await showDialog<Exam>(
      context: context,
      builder: (_) => const ExamEditDialog(),
    );
    if (result != null) {
      await context.read<AppState>().addExam(result);
    }
  }

  Future<void> _editExam(Exam exam) async {
    final result = await showDialog<Exam>(
      context: context,
      builder: (_) => ExamEditDialog(existing: exam),
    );
    if (result != null) {
      await context.read<AppState>().updateExam(result);
    }
  }
}

/// 考试编辑对话框
class ExamEditDialog extends StatefulWidget {
  final Exam? existing;
  const ExamEditDialog({super.key, this.existing});

  @override
  State<ExamEditDialog> createState() => _ExamEditDialogState();
}

class _ExamEditDialogState extends State<ExamEditDialog> {
  late TextEditingController _courseCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late DateTime _dateTime;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _courseCtrl = TextEditingController(text: e?.courseName ?? '');
    _nameCtrl = TextEditingController(text: e?.examName ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _dateTime = e?.dateTime ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '添加考试' : '编辑考试'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _courseCtrl,
              decoration: const InputDecoration(labelText: '课程名称 *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '考试名称（期中/期末等）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: '考场'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('考试时间'),
              subtitle: Text(DateUtils.formatDateTime(_dateTime)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateTime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_dateTime),
                );
                if (time != null) {
                  setState(() {
                    _dateTime = DateTime(
                        date.year, date.month, date.day, time.hour, time.minute);
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            if (_courseCtrl.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              Exam(
                id: widget.existing?.id,
                courseName: _courseCtrl.text.trim(),
                examName: _nameCtrl.text.trim(),
                location: _locationCtrl.text.trim(),
                dateTime: _dateTime,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

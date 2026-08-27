import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/homework.dart';
import '../models/course.dart';
import '../utils/date_utils.dart';

/// 作业待办页面
class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pending = state.homeworks.where((h) => !h.completed).toList()
      ..sort((a, b) {
        if (a.deadline == null && b.deadline == null) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });
    final completed = state.homeworks.where((h) => h.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('作业待办'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: '待完成 (${pending.length})'),
            Tab(text: '已完成 (${completed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(pending, state),
          _buildList(completed, state),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addHomework(state),
        icon: const Icon(Icons.add),
        label: const Text('添加作业'),
      ),
    );
  }

  Widget _buildList(List<Homework> list, AppState state) {
    if (list.isEmpty) {
      return const Center(
        child: Text('暂无作业', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final hw = list[i];
        final course = state.courses.firstWhere(
          (c) => c.id == hw.courseId,
          orElse: () => Course(name: '未分类', weekday: 0, startSection: 0, endSection: 0),
        );
        final overdue = hw.deadline != null &&
            hw.deadline!.isBefore(DateTime.now()) &&
            !hw.completed;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Checkbox(
              value: hw.completed,
              onChanged: (_) => state.toggleHomework(hw.id),
            ),
            title: Text(
              hw.title,
              style: TextStyle(
                decoration: hw.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name, style: const TextStyle(fontSize: 12)),
                if (hw.deadline != null)
                  Text(
                    '截止: ${DateUtils.formatDateTime(hw.deadline!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: overdue ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => state.deleteHomework(hw.id),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addHomework(AppState state) async {
    final result = await showDialog<Homework>(
      context: context,
      builder: (_) => HomeworkEditDialog(courses: state.courses),
    );
    if (result != null) {
      await state.addHomework(result);
    }
  }
}

/// 作业编辑对话框
class HomeworkEditDialog extends StatefulWidget {
  final List<Course> courses;
  const HomeworkEditDialog({super.key, required this.courses});

  @override
  State<HomeworkEditDialog> createState() => _HomeworkEditDialogState();
}

class _HomeworkEditDialogState extends State<HomeworkEditDialog> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String? _selectedCourseId;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    if (widget.courses.isNotEmpty) _selectedCourseId = widget.courses.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加作业'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(labelText: '关联课程'),
              items: widget.courses
                  .map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCourseId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '作业标题 *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(labelText: '作业内容'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('截止时间'),
              subtitle: Text(_deadline != null
                  ? DateUtils.formatDateTime(_deadline!)
                  : '未设置'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 3)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 23, minute: 59),
                );
                if (time != null) {
                  setState(() {
                    _deadline = DateTime(
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
            if (_titleCtrl.text.trim().isEmpty || _selectedCourseId == null)
              return;
            Navigator.pop(
              context,
              Homework(
                courseId: _selectedCourseId!,
                title: _titleCtrl.text.trim(),
                content: _contentCtrl.text.trim(),
                deadline: _deadline,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

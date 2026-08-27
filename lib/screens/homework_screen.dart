import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/homework.dart';
import '../models/course.dart';
import '../utils/date_utils.dart';
import '../widgets/glass_widgets.dart';

/// 作业待办页面 - iOS 分组列表风格
class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  int _tabIndex = 0; // 0=待完成, 1=已完成

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
    final list = _tabIndex == 0 ? pending : completed;

    return Scaffold(
      appBar: AppBar(title: const Text('作业待办')),
      body: Stack(
        children: [
          Column(
            children: [
              // iOS 分段控件
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSegmentedControl(),
              ),
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) =>
                            _buildHomeworkCard(list[i], state),
                      ),
              ),
              const SizedBox(height: 100), // 底部留白
            ],
          ),
          // 右下角玻璃悬浮添加按钮
          Positioned(
            right: 16,
            bottom: 100,
            child: GlassPillButton(
              icon: Icons.add,
              label: '添加作业',
              onPressed: () => _addHomework(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildSegment('待完成', 0),
          _buildSegment('已完成', 1),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).cardColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? null : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              _tabIndex == 0 ? '暂无待完成作业' : '暂无已完成作业',
              style: const TextStyle(fontSize: 17, color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildHomeworkCard(Homework hw, AppState state) {
    final course = state.courses.firstWhere(
      (c) => c.id == hw.courseId,
      orElse: () => Course(
          name: '未分类', weekday: 0, startSection: 0, endSection: 0),
    );
    final overdue = hw.deadline != null &&
        hw.deadline!.isBefore(DateTime.now()) &&
        !hw.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 复选框
              GestureDetector(
                onTap: () => state.toggleHomework(hw.id),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: hw.completed
                        ? const Color(0xFF34C759)
                        : Colors.transparent,
                    border: Border.all(
                      color: hw.completed
                          ? const Color(0xFF34C759)
                          : Colors.grey,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: hw.completed
                      ? const Icon(Icons.check,
                          size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hw.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: hw.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: hw.completed ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.name,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500]),
                    ),
                    if (hw.deadline != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '截止: ${AppDateUtils.formatDateTime(hw.deadline!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: overdue ? Colors.red : Colors.grey[500],
                          fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 删除
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: Colors.grey[400]),
                onPressed: () => state.deleteHomework(hw.id),
              ),
            ],
          ),
        ),
      ),
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
                  ? AppDateUtils.formatDateTime(_deadline!)
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

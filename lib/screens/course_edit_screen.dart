import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/course.dart';
import '../utils/constants.dart';

/// 课程添加/编辑页面
class CourseEditScreen extends StatefulWidget {
  final Course? existingCourse;
  const CourseEditScreen({super.key, this.existingCourse});

  @override
  State<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _teacherCtrl;
  late TextEditingController _classroomCtrl;
  late TextEditingController _remarkCtrl;

  late int _weekday;
  late int _startSection;
  late int _endSection;
  late WeekType _weekType;
  late int _colorIndex;
  late int _remindMinutes;
  late RangeValues _weekRange;
  late int _totalWeeks;

  bool get _isEdit => widget.existingCourse != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCourse;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _teacherCtrl = TextEditingController(text: c?.teacher ?? '');
    _classroomCtrl = TextEditingController(text: c?.classroom ?? '');
    _remarkCtrl = TextEditingController(text: c?.remark ?? '');
    _weekday = c?.weekday ?? 1;
    _startSection = c?.startSection ?? 1;
    _endSection = c?.endSection ?? 1;
    _weekType = c?.weekType ?? WeekType.all;
    _colorIndex = c?.colorIndex ?? 0;
    _remindMinutes = c?.remindMinutes ?? 10;
    _totalWeeks = 20;
    final startW = c?.weeks.isNotEmpty == true ? c!.weeks.first : 1;
    final endW = c?.weeks.isNotEmpty == true ? c!.weeks.last : 20;
    _weekRange = RangeValues(startW.toDouble(), endW.toDouble());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _totalWeeks = context.read<AppState>().settings.totalWeeks;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teacherCtrl.dispose();
    _classroomCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final maxSection = state.settings.timeSlots.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑课程' : '添加课程'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 课程名称
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '课程名称 *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入课程名称' : null,
            ),
            const SizedBox(height: 16),
            // 老师 + 教室
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _teacherCtrl,
                    decoration: const InputDecoration(labelText: '授课老师'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _classroomCtrl,
                    decoration: const InputDecoration(labelText: '教室'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 星期
            _buildSectionTitle('星期'),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final selected = _weekday == i + 1;
                return ChoiceChip(
                  label: Text(kWeekdays[i]),
                  selected: selected,
                  onSelected: (_) => setState(() => _weekday = i + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            // 节次
            _buildSectionTitle('节次'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _startSection,
                    decoration: const InputDecoration(labelText: '开始节次'),
                    items: List.generate(
                      maxSection,
                      (i) => DropdownMenuItem(value: i + 1, child: Text('第 ${i + 1} 节')),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _startSection = v!;
                        if (_endSection < _startSection) _endSection = _startSection;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _endSection,
                    decoration: const InputDecoration(labelText: '结束节次'),
                    items: List.generate(
                      maxSection - _startSection + 1,
                      (i) => DropdownMenuItem(
                          value: _startSection + i,
                          child: Text('第 ${_startSection + i} 节')),
                    ),
                    onChanged: (v) => setState(() => _endSection = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 周范围
            _buildSectionTitle('上课周范围 (${_weekRange.start.toInt()} - ${_weekRange.end.toInt()} 周)'),
            RangeSlider(
              values: _weekRange,
              min: 1,
              max: _totalWeeks.toDouble(),
              divisions: _totalWeeks - 1,
              labels: RangeLabels(
                '${_weekRange.start.toInt()}周',
                '${_weekRange.end.toInt()}周',
              ),
              onChanged: (v) => setState(() => _weekRange = v),
            ),
            // 单双周
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('每周'),
                  selected: _weekType == WeekType.all,
                  onSelected: (_) => setState(() => _weekType = WeekType.all),
                ),
                ChoiceChip(
                  label: const Text('单周'),
                  selected: _weekType == WeekType.odd,
                  onSelected: (_) => setState(() => _weekType = WeekType.odd),
                ),
                ChoiceChip(
                  label: const Text('双周'),
                  selected: _weekType == WeekType.even,
                  onSelected: (_) => setState(() => _weekType = WeekType.even),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 颜色
            _buildSectionTitle('颜色'),
            Wrap(
              spacing: 8,
              children: List.generate(kCourseColors.length, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kCourseColors[i],
                      shape: BoxShape.circle,
                      border: _colorIndex == i
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // 提醒
            _buildSectionTitle('上课提醒'),
            DropdownButtonFormField<int>(
              value: _remindMinutes,
              decoration: const InputDecoration(labelText: '提前提醒'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('不提醒')),
                DropdownMenuItem(value: 5, child: Text('提前 5 分钟')),
                DropdownMenuItem(value: 10, child: Text('提前 10 分钟')),
                DropdownMenuItem(value: 15, child: Text('提前 15 分钟')),
                DropdownMenuItem(value: 30, child: Text('提前 30 分钟')),
              ],
              onChanged: (v) => setState(() => _remindMinutes = v!),
            ),
            const SizedBox(height: 16),
            // 备注
            TextFormField(
              controller: _remarkCtrl,
              decoration: const InputDecoration(labelText: '备注'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // 保存按钮
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? '保存修改' : '添加课程'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final weeks = List.generate(
      _weekRange.end.toInt() - _weekRange.start.toInt() + 1,
      (i) => _weekRange.start.toInt() + i,
    );

    final course = Course(
      id: widget.existingCourse?.id,
      name: _nameCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
      classroom: _classroomCtrl.text.trim(),
      weekday: _weekday,
      startSection: _startSection,
      endSection: _endSection,
      weeks: weeks,
      weekType: _weekType,
      remark: _remarkCtrl.text.trim(),
      colorIndex: _colorIndex,
      remindMinutes: _remindMinutes,
    );

    final state = context.read<AppState>();
    if (_isEdit) {
      await state.updateCourse(course);
    } else {
      await state.addCourse(course);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除课程'),
        content: const Text('确定要删除这门课程吗？关联的作业也会被删除。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AppState>().deleteCourse(widget.existingCourse!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

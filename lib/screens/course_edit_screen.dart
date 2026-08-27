import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/course.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// 课程编辑页面：iOS 分组表单风格
class CourseEditScreen extends StatefulWidget {
  final Course? course;

  const CourseEditScreen({super.key, this.course});

  @override
  State<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _teacherController;
  late TextEditingController _classroomController;
  late TextEditingController _remarkController;
  late int _weekday;
  late int _startSection;
  late int _endSection;
  late int _startWeek;
  late int _endWeek;
  late WeekType _weekType;
  late int _colorIndex;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _nameController = TextEditingController(text: c?.name ?? '');
    _teacherController = TextEditingController(text: c?.teacher ?? '');
    _classroomController = TextEditingController(text: c?.classroom ?? '');
    _remarkController = TextEditingController(text: c?.remark ?? '');
    _weekday = c?.weekday ?? 1;
    _startSection = c?.startSection ?? 1;
    _endSection = c?.endSection ?? 1;
    _startWeek = c?.weeks.first ?? 1;
    _endWeek = c?.weeks.last ?? 20;
    _weekType = c?.weekType ?? WeekType.all;
    _colorIndex = c?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.course != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑课程' : '添加课程'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基本信息分组
          _buildSectionTitle('基本信息'),
          _buildGroup([
            _buildTextField('课程名称', _nameController, placeholder: '必填'),
            _buildDivider(),
            _buildTextField('授课老师', _teacherController),
            _buildDivider(),
            _buildTextField('教室', _classroomController),
          ]),
          const SizedBox(height: 24),

          // 时间分组
          _buildSectionTitle('上课时间'),
          _buildGroup([
            _buildPickerRow('星期', kWeekdays[_weekday]!, () => _showWeekdayPicker()),
            _buildDivider(),
            _buildPickerRow('开始节次', '第 $_startSection 节', () => _showSectionPicker(true)),
            _buildDivider(),
            _buildPickerRow('结束节次', '第 $_endSection 节', () => _showSectionPicker(false)),
          ]),
          const SizedBox(height: 24),

          // 周范围分组
          _buildSectionTitle('上课周'),
          _buildGroup([
            _buildPickerRow('开始周', '第 $_startWeek 周', () => _showWeekPicker(true)),
            _buildDivider(),
            _buildPickerRow('结束周', '第 $_endWeek 周', () => _showWeekPicker(false)),
            _buildDivider(),
            _buildWeekTypeSelector(),
          ]),
          const SizedBox(height: 24),

          // 颜色分组
          _buildSectionTitle('课程颜色'),
          _buildColorPicker(),
          const SizedBox(height: 24),

          // 备注分组
          _buildSectionTitle('备注'),
          _buildGroup([
            _buildTextField('备注', _remarkController, maxLines: 3),
          ]),
          const SizedBox(height: 32),

          if (isEdit)
            _buildDeleteButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? placeholder, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(height: 1, color: Theme.of(context).dividerColor),
    );
  }

  Widget _buildPickerRow(String label, String value, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.right),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text('单双周',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildWeekTypeChip(WeekType.all, '每周'),
                const SizedBox(width: 8),
                _buildWeekTypeChip(WeekType.odd, '单周'),
                const SizedBox(width: 8),
                _buildWeekTypeChip(WeekType.even, '双周'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTypeChip(WeekType type, String label) {
    final selected = _weekType == type;
    return GestureDetector(
      onTap: () => setState(() => _weekType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(kCourseGradients.length, (index) {
          final gradient = kCourseGradients[index];
          final selected = _colorIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _colorIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: gradient[1].withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _delete,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '删除课程',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWeekdayPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _buildPickerSheet(
        title: '选择星期',
        items: kWeekdays,
        initialIndex: _weekday - 1,
        onSelected: (index) => setState(() => _weekday = index + 1),
      ),
    );
  }

  void _showSectionPicker(bool isStart) {
    final maxSection = context.read<AppState>().settings.timeSlots.length;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _buildPickerSheet(
        title: isStart ? '开始节次' : '结束节次',
        items: List.generate(maxSection, (i) => '第 ${i + 1} 节'),
        initialIndex: (isStart ? _startSection : _endSection) - 1,
        onSelected: (index) {
          setState(() {
            if (isStart) {
              _startSection = index + 1;
              if (_endSection < _startSection) _endSection = _startSection;
            } else {
              _endSection = index + 1;
              if (_startSection > _endSection) _startSection = _endSection;
            }
          });
        },
      ),
    );
  }

  void _showWeekPicker(bool isStart) {
    final totalWeeks = context.read<AppState>().settings.totalWeeks;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _buildPickerSheet(
        title: isStart ? '开始周' : '结束周',
        items: List.generate(totalWeeks, (i) => '第 ${i + 1} 周'),
        initialIndex: (isStart ? _startWeek : _endWeek) - 1,
        onSelected: (index) {
          setState(() {
            if (isStart) {
              _startWeek = index + 1;
              if (_endWeek < _startWeek) _endWeek = _startWeek;
            } else {
              _endWeek = index + 1;
              if (_startWeek > _endWeek) _startWeek = _endWeek;
            }
          });
        },
      ),
    );
  }

  Widget _buildPickerSheet({
    required String title,
    required List<String> items,
    required int initialIndex,
    required ValueChanged<int> onSelected,
  }) {
    int selectedIndex = initialIndex;
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final selected = index == selectedIndex;
                    return ListTile(
                      title: Text(items[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: selected
                                ? Theme.of(context).primaryColor
                                : null,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          )),
                      onTap: () {
                        setSheetState(() => selectedIndex = index);
                        onSelected(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入课程名称')),
      );
      return;
    }

    final weeks =
        List.generate(_endWeek - _startWeek + 1, (i) => _startWeek + i);

    final course = Course(
      id: widget.course?.id,
      name: _nameController.text.trim(),
      teacher: _teacherController.text.trim(),
      classroom: _classroomController.text.trim(),
      weekday: _weekday,
      startSection: _startSection,
      endSection: _endSection,
      weeks: weeks,
      weekType: _weekType,
      remark: _remarkController.text.trim(),
      colorIndex: _colorIndex,
    );

    final state = context.read<AppState>();
    if (widget.course != null) {
      state.updateCourse(course);
    } else {
      state.addCourse(course);
    }
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除课程'),
        content: const Text('确定要删除这门课程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteCourse(widget.course!.id!);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('删除',
                style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );
  }
}

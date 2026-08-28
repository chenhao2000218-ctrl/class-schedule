import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/exam.dart';
import '../utils/date_utils.dart';
import '../widgets/glass_widgets.dart';

/// 考试安排页面 - iOS 分组列表风格 + 左滑操作
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
      ..sort((a, b) {
        // 置顶的排前面
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.dateTime.compareTo(b.dateTime);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('考试安排')),
      body: Stack(
        children: [
          exams.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 100),
                  itemCount: exams.length,
                  itemBuilder: (ctx, i) {
                    final exam = exams[i];
                    final isPast = exam.dateTime.isBefore(DateTime.now());
                    return _SwipeableExamCard(
                      exam: exam,
                      isPast: isPast,
                      onDelete: () => state.deleteExam(exam.id),
                      onTogglePin: () {
                        final updated = Exam(
                          id: exam.id,
                          courseName: exam.courseName,
                          examName: exam.examName,
                          dateTime: exam.dateTime,
                          location: exam.location,
                          remark: exam.remark,
                          remind: exam.remind,
                          isPinned: !exam.isPinned,
                        );
                        state.updateExam(updated);
                      },
                      onEdit: () => _editExam(exam),
                    );
                  },
                ),
          // 右下角玻璃悬浮添加按钮
          Positioned(
            right: 16,
            bottom: 100,
            child: GlassPillButton(
              icon: Icons.add,
              label: '添加考试',
              onPressed: _addExam,
            ),
          ),
        ],
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
            const Text('暂无考试安排',
                style: TextStyle(fontSize: 17, color: Colors.grey)),
          ],
        ),
      );

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

/// 可左滑的考试卡片
class _SwipeableExamCard extends StatefulWidget {
  final Exam exam;
  final bool isPast;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;

  const _SwipeableExamCard({
    required this.exam,
    required this.isPast,
    required this.onDelete,
    required this.onTogglePin,
    required this.onEdit,
  });

  @override
  State<_SwipeableExamCard> createState() => _SwipeableExamCardState();
}

class _SwipeableExamCardState extends State<_SwipeableExamCard>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  static const double _actionWidth = 80.0;
  static const double _maxDrag = _actionWidth * 3; // 三个按钮

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _dragExtent += details.delta.dx;
            if (_dragExtent > 0) _dragExtent = 0;
            if (_dragExtent < -_maxDrag) _dragExtent = -_maxDrag;
          });
        },
        onHorizontalDragEnd: (details) {
          setState(() {
            if (_dragExtent < -_maxDrag / 2) {
              _dragExtent = -_maxDrag;
            } else {
              _dragExtent = 0;
            }
          });
        },
        child: Stack(
          children: [
            // 背后的操作按钮
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: widget.exam.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    label: widget.exam.isPinned ? '取消置顶' : '置顶',
                    color: Colors.orange,
                    onTap: () {
                      widget.onTogglePin();
                      _resetDrag();
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.edit,
                    label: '编辑',
                    color: Colors.blue,
                    onTap: () {
                      widget.onEdit();
                      _resetDrag();
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: '删除',
                    color: Colors.red,
                    onTap: () {
                      widget.onDelete();
                      _resetDrag();
                    },
                  ),
                ],
              ),
            ),
            // 前景卡片
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: _dragExtent,
              right: -_dragExtent,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: widget.exam.isPinned
                      ? Border.all(
                          color: Colors.orange.withOpacity(0.5), width: 1)
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // 置顶标记
                        if (widget.exam.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.push_pin,
                                size: 16, color: Colors.orange),
                          ),
                        // 日期圆形
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.isPast
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.exam.dateTime.day}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // 内容
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.exam.courseName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: widget.isPast
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: widget.isPast ? Colors.grey : null,
                                ),
                              ),
                              if (widget.exam.examName.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(widget.exam.examName,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500])),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                '${AppDateUtils.formatDateTime(widget.exam.dateTime)}'
                                '${widget.exam.location.isNotEmpty ? ' · ${widget.exam.location}' : ''}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        // 滑动提示
                        Icon(Icons.chevron_left,
                            size: 18, color: Colors.grey.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _actionWidth,
        decoration: BoxDecoration(color: color),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _resetDrag() {
    setState(() => _dragExtent = 0);
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
    _dateTime =
        e?.dateTime ?? DateTime.now().add(const Duration(days: 7));
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
              decoration:
                  const InputDecoration(labelText: '考试名称（期中/期末等）'),
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
              subtitle: Text(AppDateUtils.formatDateTime(_dateTime)),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
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
                isPinned: widget.existing?.isPinned ?? false,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

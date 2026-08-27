import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/time_slot.dart';

/// 作息时间设置页面：自由设置每节课的开始/结束时间
class ScheduleSettingsScreen extends StatefulWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  late List<TimeSlot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List.from(context.read<AppState>().settings.timeSlots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作息时间'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _slots.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final item = _slots.removeAt(oldIdx);
                  _slots.insert(newIdx, item);
                  _reindex();
                });
              },
              itemBuilder: (ctx, i) => _buildSlotTile(i),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addSlot,
                    icon: const Icon(Icons.add),
                    label: const Text('添加一节'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetDefault,
                    icon: const Icon(Icons.restore),
                    label: const Text('恢复默认'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotTile(int index) {
    final slot = _slots[index];
    return Card(
      key: ValueKey(slot.section),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.drag_handle, color: Colors.grey),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              child: Text('${slot.section}',
                  style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                label: '开始',
                value: slot.startTime,
                onChanged: (v) => setState(() => slot.startTime = v),
              ),
            ),
            const Text('—', style: TextStyle(color: Colors.grey)),
            Expanded(
              child: _buildTimeField(
                label: '结束',
                value: slot.endTime,
                onChanged: (v) => setState(() => slot.endTime = v),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _slots.length > 1
                  ? () => setState(() {
                        _slots.removeAt(index);
                        _reindex();
                      })
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// 时间选择字段
  Widget _buildTimeField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final parts = value.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ),
        );
        if (picked != null) {
          onChanged(
            '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(value, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  void _addSlot() {
    final last = _slots.last;
    final lastEnd = last.endTime.split(':');
    final hour = int.parse(lastEnd[0]);
    final minute = int.parse(lastEnd[1]) + 10;
    final startH = minute >= 60 ? hour + 1 : hour;
    final startM = minute >= 60 ? minute - 60 : minute;
    final endH = startH + 1;
    setState(() {
      _slots.add(TimeSlot(
        section: _slots.length + 1,
        startTime:
            '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}',
        endTime:
            '${endH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}',
      ));
    });
  }

  void _resetDefault() {
    setState(() => _slots = defaultTimeSlots());
  }

  void _reindex() {
    for (var i = 0; i < _slots.length; i++) {
      _slots[i].section = i + 1;
    }
  }

  Future<void> _save() async {
    await context.read<AppState>().updateTimeSlots(_slots);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('作息时间已保存')),
      );
      Navigator.pop(context);
    }
  }
}

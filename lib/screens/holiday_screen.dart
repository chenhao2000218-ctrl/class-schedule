import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/holiday.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

/// 假期与调休管理页面
class HolidayScreen extends StatefulWidget {
  const HolidayScreen({super.key});

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final holidays = List.from(state.holidays)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: const Text('假期与调休')),
      body: holidays.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.beach_access, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无假期或调休安排',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: holidays.length,
              itemBuilder: (ctx, i) {
                final h = holidays[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      h.isHoliday ? Icons.holiday_village : Icons.swap_horiz,
                      color: h.isHoliday ? Colors.orange : Colors.blue,
                    ),
                    title: Text(h.name.isNotEmpty ? h.name : (h.isHoliday ? '假期' : '调休')),
                    subtitle: Text(
                      '${AppDateUtils.formatDate(h.date)}'
                      '${h.isAdjust && h.weekdayOverride != null ? ' · 上${kWeekdays[h.weekdayOverride! - 1]}的课' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => state.deleteHoliday(h.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHoliday,
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
    );
  }

  Future<void> _addHoliday() async {
    final type = await showModalBottomSheet<HolidayType>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.holiday_village, color: Colors.orange),
              title: const Text('添加假期'),
              subtitle: const Text('该日期自动隐藏所有课程'),
              onTap: () => Navigator.pop(ctx, HolidayType.holiday),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
              title: const Text('添加调休'),
              subtitle: const Text('该日期按指定星期显示课程'),
              onTap: () => Navigator.pop(ctx, HolidayType.adjust),
            ),
          ],
        ),
      ),
    );
    if (type == null) return;

    // 选择日期
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null) return;

    int? weekdayOverride;
    String name = '';

    if (type == HolidayType.adjust) {
      // 选择调休到星期几
      weekdayOverride = await showModalBottomSheet<int>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              7,
              (i) => ListTile(
                title: Text('上${kWeekdays[i]}的课'),
                onTap: () => Navigator.pop(ctx, i + 1),
              ),
            ),
          ),
        ),
      );
      if (weekdayOverride == null) return;
      name = '调休上${kWeekdays[weekdayOverride - 1]}课';
    } else {
      name = '假期';
    }

    await context.read<AppState>().addHoliday(Holiday(
          date: date,
          type: type,
          name: name,
          weekdayOverride: weekdayOverride,
        ));
  }
}

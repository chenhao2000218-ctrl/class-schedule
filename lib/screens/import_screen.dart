import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../services/ics_service.dart';
import '../services/storage_service.dart';

/// 导入页面：ICS 链接导入、ICS 文件导入、JSON 恢复
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  final _icsService = IcsService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'ICS 链接'),
            Tab(text: 'ICS 文件'),
            Tab(text: 'JSON 恢复'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildUrlImport(),
          _buildFileImport(),
          _buildJsonRestore(),
        ],
      ),
    );
  }

  /// ICS 链接导入
  Widget _buildUrlImport() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '粘贴教务系统的 ICS 链接，一键导入课表',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'ICS 链接',
              hintText: 'https://.../schedule.ics',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _importFromUrl,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('开始导入'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '提示：\n'
            '1. 在教务系统课表页面找到"导出日历/ICS"功能\n'
            '2. 复制生成的链接粘贴到上方\n'
            '3. 导入后可在课程列表中手动调整节次和老师信息',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// ICS 文件导入
  Widget _buildFileImport() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择本地 ICS 文件导入课表',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _importFromFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('选择 ICS 文件'),
            ),
          ),
        ],
      ),
    );
  }

  /// JSON 恢复
  Widget _buildJsonRestore() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '从之前导出的 JSON 备份文件恢复全部数据',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '注意：恢复将覆盖当前所有数据！',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _restoreFromJson,
              icon: const Icon(Icons.restore),
              label: const Text('选择备份文件'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 ICS 链接')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final courses = await _icsService.importFromUrl(url);
      final count = await context.read<AppState>().importCourses(courses);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 $count 门课程')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics'],
    );
    if (result == null || result.files.single.path == null) return;

    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final courses = _icsService.parseIcs(content);
      final count = await context.read<AppState>().importCourses(courses);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 $count 门课程')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _restoreFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('恢复将覆盖当前所有课程、考试、作业数据，确定继续吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定恢复')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      jsonDecode(content); // 验证格式
      final storage = StorageService();
      await storage.init();
      await storage.importAll(content);
      if (mounted) {
        await context.read<AppState>().init();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据恢复成功')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    }
  }
}

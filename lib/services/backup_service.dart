import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_service.dart';

/// JSON 备份与恢复服务
class BackupService {
  final StorageService storage;

  BackupService(this.storage);

  /// 导出备份到文件并返回路径
  Future<String> exportToFile() async {
    final data = storage.exportAll();
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        '课表备份_${DateTime.now().toString().replaceAll(':', '-').split('.')[0]}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(data);
    return file.path;
  }

  /// 分享备份文件
  Future<void> shareBackup() async {
    final path = await exportToFile();
    await Share.shareXFiles([XFile(path)], text: '课表数据备份');
  }

  /// 从 JSON 字符串恢复
  Future<void> restoreFromJson(String jsonStr) async {
    // 验证 JSON 格式
    final data = jsonDecode(jsonStr);
    if (data is! Map || !data.containsKey('courses')) {
      throw const FormatException('无效的备份文件格式');
    }
    await storage.importAll(jsonStr);
  }

  /// 从文件恢复
  Future<void> restoreFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在');
    }
    final content = await file.readAsString();
    await restoreFromJson(content);
  }
}

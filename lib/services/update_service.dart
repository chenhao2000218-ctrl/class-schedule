import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// 应用内更新服务
/// 通过 GitHub Pages 托管 IPA 和版本信息，实现 OTA 在线更新
class UpdateService {
  // GitHub Pages 上的版本信息文件地址
  static const String _versionUrl =
      'https://chenhao2000218-ctrl.github.io/class-schedule/version.json';

  /// 检查更新
  /// 返回 [UpdateInfo]，如果没有更新返回 null
  static Future<UpdateInfo?> checkUpdate(String currentVersion) async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = data['version'] as String;
      final buildNumber = data['build_number'] as int? ?? 1;
      final changelog = data['changelog'] as String? ?? '';
      final manifestUrl = data['manifest_url'] as String? ?? '';

      // 解析当前版本（格式：1.0.0+1）
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion('$latestVersion+$buildNumber');

      // 比较版本号
      final hasUpdate = _isNewer(latest, current);

      if (hasUpdate && manifestUrl.isNotEmpty) {
        return UpdateInfo(
          version: latestVersion,
          buildNumber: buildNumber,
          changelog: changelog,
          manifestUrl: manifestUrl,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 触发 OTA 安装
  /// 跳转到 Safari 打开 itms-services:// 链接
  static Future<bool> installUpdate(String manifestUrl) async {
    final url = 'itms-services://?action=download-manifest&url=$manifestUrl';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// 解析版本字符串 "1.0.0+1" → [1, 0, 0, 1]
  static List<int> _parseVersion(String version) {
    final parts = version.split('+');
    final ver = parts[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    while (ver.length < 3) {
      ver.add(0);
    }
    return [...ver, build];
  }

  /// 比较版本，a 是否比 b 新
  static bool _isNewer(List<int> a, List<int> b) {
    for (var i = 0; i < 4; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av > bv) return true;
      if (av < bv) return false;
    }
    return false;
  }
}

/// 更新信息
class UpdateInfo {
  final String version;
  final int buildNumber;
  final String changelog;
  final String manifestUrl;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    required this.manifestUrl,
  });
}

/// 显示更新对话框
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo info,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Icon(Icons.system_update,
              color: isDark ? Colors.white : const Color(0xFF007AFF)),
          const SizedBox(width: 8),
          const Text('发现新版本'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'v${info.version} (${info.buildNumber})',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          if (info.changelog.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '更新内容：',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              info.changelog,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '点击更新后将跳转到 Safari 安装，安装完成后打开即为新版本。',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('稍后'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await UpdateService.installUpdate(info.manifestUrl);
          },
          child: const Text('立即更新'),
        ),
      ],
    ),
  );
}

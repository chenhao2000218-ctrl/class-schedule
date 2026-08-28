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

/// 显示更新提示（顶部柔和横幅，不打断操作）
void showUpdateBanner(
  BuildContext context,
  UpdateInfo info,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -100, end: 0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C1E).withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.system_update,
                            size: 20, color: Color(0xFF007AFF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '发现新版本 v${info.version}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '点击更新 · ${info.changelog.isEmpty ? '体验优化' : info.changelog}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          entry.remove();
                          UpdateService.installUpdate(info.manifestUrl);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '更新',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => entry.remove(),
                        child: Icon(Icons.close,
                            size: 18,
                            color: isDark
                                ? Colors.white38
                                : Colors.black38),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  // 8秒后自动消失
  Future.delayed(const Duration(seconds: 8), () {
    if (entry.mounted) entry.remove();
  });
}

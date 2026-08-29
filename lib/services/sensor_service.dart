import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// 传感器服务 - 监听陀螺仪/加速度计，用于液态玻璃动态光效
class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // 归一化的倾斜角度（-1.0 ~ 1.0）
  double _tiltX = 0;
  double _tiltY = 0;
  double get tiltX => _tiltX;
  double get tiltY => _tiltY;

  StreamSubscription? _accelSub;
  final List<void Function(double x, double y)> _listeners = [];
  DateTime _lastUpdate = DateTime.now();
  static const _minInterval = Duration(milliseconds: 100); // 节流：最多10fps

  /// 启动监听
  void start() {
    if (_accelSub != null) return;
    _accelSub = accelerometerEventStream().listen((event) {
      // 节流，避免频繁重绘导致文字渲染异常
      final now = DateTime.now();
      if (now.difference(_lastUpdate) < _minInterval) return;
      _lastUpdate = now;

      // 归一化到 -1.0 ~ 1.0
      _tiltX = (event.x / 9.8).clamp(-1.0, 1.0);
      _tiltY = (event.y / 9.8).clamp(-1.0, 1.0);
      for (final listener in _listeners) {
        listener(_tiltX, _tiltY);
      }
    });
  }

  /// 停止监听
  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  /// 添加监听器
  void addListener(void Function(double x, double y) listener) {
    _listeners.add(listener);
    start();
  }

  /// 移除监听器
  void removeListener(void Function(double x, double y) listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) stop();
  }
}

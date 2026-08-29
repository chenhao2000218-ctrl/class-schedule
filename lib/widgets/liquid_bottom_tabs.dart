import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'glass_widgets.dart';

/// 液态玻璃底部标签栏（完整移植 Kyant0 LiquidBottomTabs）
/// 特性：
/// - 阻尼拖拽切换（手指左右滑动切换 tab）
/// - 按压变形（按下时指示器横向拉伸）
/// - 速度形变（快速滑动时指示器拉伸）
/// - 色差折射（选中指示器的玻璃透镜效果）
/// - 内阴影 + 动态高光
class LiquidBottomTabs extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<BottomTabItem> tabs;

  const LiquidBottomTabs({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.tabs,
  });

  @override
  State<LiquidBottomTabs> createState() => _LiquidBottomTabsState();
}

class _LiquidBottomTabsState extends State<LiquidBottomTabs>
    with TickerProviderStateMixin {
  // 拖拽动画控制器
  late final AnimationController _dragController;
  late final AnimationController _pressController;

  // 拖拽位置（0.0 ~ tabs.length-1）
  double _dragValue = 0;
  // 目标位置
  double _targetValue = 0;
  // 拖拽速度
  double _velocity = 0;
  // 是否正在拖拽
  bool _isDragging = false;
  // 是否按下
  bool _isPressed = false;

  // 上次拖拽位置（用于计算速度）
  double _lastDragDx = 0;
  DateTime _lastDragTime = DateTime.now();

  static const double _indicatorHeight = 60.0;
  static const double _inset = 3.0;

  @override
  void initState() {
    super.initState();
    _dragValue = widget.currentIndex.toDouble();
    _targetValue = widget.currentIndex.toDouble();

    _dragController = AnimationController(
      vsync: this,
      lowerBound: -1,
      upperBound: widget.tabs.length.toDouble(),
      value: _dragValue,
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void didUpdateWidget(LiquidBottomTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _targetValue = widget.currentIndex.toDouble();
      _animateToTarget();
    }
  }

  @override
  void dispose() {
    _dragController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  /// 弹簧动画到目标位置
  void _animateToTarget() {
    _dragController.animateTo(
      _targetValue,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    _dragValue = _targetValue;
  }

  /// 处理水平拖拽开始
  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _isPressed = true;
    _pressController.forward();
    _lastDragDx = details.globalPosition.dx;
    _lastDragTime = DateTime.now();
    _dragController.stop();
  }

  /// 处理水平拖拽更新
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final now = DateTime.now();
    final dt = now.difference(_lastDragTime).inMilliseconds / 1000.0;
    final dx = details.globalPosition.dx - _lastDragDx;

    // 计算速度
    if (dt > 0) {
      _velocity = dx / dt;
    }

    _lastDragDx = details.globalPosition.dx;
    _lastDragTime = now;

    setState(() {
      // 拖拽距离 / tab宽度 = 位置变化
      final tabWidth = context.size!.width / widget.tabs.length;
      _dragValue = (_dragValue + dx / tabWidth)
          .clamp(0.0, widget.tabs.length - 1.0);
      _dragController.value = _dragValue;
    });
  }

  /// 处理拖拽结束
  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    _isPressed = false;
    _pressController.reverse();

    // 根据速度和位置决定目标 tab
    final velocity = details.velocity.pixelsPerSecond.dx;
    int targetIndex = _dragValue.round();

    // 速度足够大时，按速度方向切换
    if (velocity.abs() > 300) {
      if (velocity > 0) {
        targetIndex = (_dragValue + 0.5).floor();
      } else {
        targetIndex = (_dragValue + 0.5).ceil();
      }
    }

    targetIndex = targetIndex.clamp(0, widget.tabs.length - 1);
    _targetValue = targetIndex.toDouble();
    _animateToTarget();

    if (targetIndex != widget.currentIndex) {
      widget.onTabSelected(targetIndex);
    }
  }

  /// 处理点击 tab
  void _onTabTap(int index) {
    _targetValue = index.toDouble();
    _animateToTarget();
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabCount = widget.tabs.length;

    return GlassPillBar(
      padding: const EdgeInsets.symmetric(horizontal: _inset, vertical: _inset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabCount;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: SizedBox(
              height: _indicatorHeight,
              child: Stack(
                children: [
                  // 选中指示器（玻璃透镜效果）
                  AnimatedBuilder(
                    animation: Listenable.merge([_dragController, _pressController]),
                    builder: (context, child) {
                      final pressProgress = _pressController.value;
                      // 速度形变：快速滑动时横向拉伸
                      final velocityFactor =
                          (_velocity / 2000).clamp(-0.15, 0.15);
                      final scaleX = 1.0 +
                          pressProgress * 0.08 +
                          velocityFactor.abs();
                      final scaleY = 1.0 - pressProgress * 0.05;

                      return Positioned(
                        left: _dragController.value * tabWidth,
                        top: 0,
                        width: tabWidth,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..scale(scaleX, scaleY),
                          child: Container(
                            height: _indicatorHeight,
                            alignment: Alignment.center,
                            child: _LiquidIndicator(
                              width: tabWidth - _inset * 2,
                              height: _indicatorHeight,
                              pressProgress: pressProgress,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Tab 按钮层
                  Row(
                    children: List.generate(tabCount, (index) {
                      return _buildTabItem(index, tabWidth, isDark);
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabItem(int index, double tabWidth, bool isDark) {
    final tab = widget.tabs[index];
    // 选中进度（0.0 ~ 1.0），支持拖拽过程中的渐变
    final selectionProgress = (1.0 - (_dragController.value - index).abs())
        .clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTap(index),
      child: SizedBox(
        width: tabWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: 1.0 + selectionProgress * 0.1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                tab.icon,
                size: 22,
                color: Color.lerp(
                  Colors.grey,
                  isDark ? Colors.white : const Color(0xFF007AFF),
                  selectionProgress,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color.lerp(
                  Colors.grey,
                  isDark ? Colors.white : const Color(0xFF007AFF),
                  selectionProgress,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 液态玻璃选中指示器（带色差折射 + 内阴影）
class _LiquidIndicator extends StatelessWidget {
  final double width;
  final double height;
  final double pressProgress;
  final bool isDark;

  const _LiquidIndicator({
    required this.width,
    required this.height,
    required this.pressProgress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: height / 2,
      displacementScale: 15 + pressProgress * 10,
      aberration: 0.3 + pressProgress * 0.2,
      edgeWidth: 0.12,
      blurAmount: 10,
      interactive: false,
      enableInnerShadow: true,
      innerShadowAlpha: 0.12 + pressProgress * 0.08,
      padding: EdgeInsets.zero,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.12 + pressProgress * 0.06)
              : const Color(0xFF007AFF).withOpacity(0.12 + pressProgress * 0.06),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

/// 底部 tab 项
class BottomTabItem {
  final IconData icon;
  final String label;

  const BottomTabItem({required this.icon, required this.label});
}

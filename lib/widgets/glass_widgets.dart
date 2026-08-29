import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/sensor_service.dart';

/// 液态玻璃组件 - BackdropFilter 模糊 + 自定义 shader 边缘折射 + 内阴影 + 动态高光

// 缓存 shader program
ui.FragmentProgram? _cachedProgram;
bool _shaderLoading = false;
bool _shaderFailed = false;

Future<ui.FragmentProgram?> _loadProgram() async {
  if (_cachedProgram != null) return _cachedProgram;
  if (_shaderLoading || _shaderFailed) return null;
  _shaderLoading = true;
  try {
    _cachedProgram =
        await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
    return _cachedProgram;
  } catch (_) {
    _shaderFailed = true;
    return null;
  } finally {
    _shaderLoading = false;
  }
}

/// 玻璃边缘折射绘制器
class _GlassRefractionPainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final double displacementScale;
  final double aberration;
  final double edgeWidth;
  final double time;

  _GlassRefractionPainter({
    required this.shader,
    required this.displacementScale,
    required this.aberration,
    required this.edgeWidth,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shader == null) return;
    shader!.setFloat(0, size.width);
    shader!.setFloat(1, size.height);
    shader!.setFloat(2, displacementScale);
    shader!.setFloat(3, aberration);
    shader!.setFloat(4, edgeWidth);
    shader!.setFloat(5, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassRefractionPainter old) =>
      old.shader != shader ||
      old.displacementScale != displacementScale ||
      old.aberration != aberration ||
      old.edgeWidth != edgeWidth ||
      old.time != time;
}

/// 内阴影绘制器
class _InnerShadowPainter extends CustomPainter {
  final double radius;
  final double alpha;
  final Color color;

  _InnerShadowPainter({
    required this.radius,
    required this.alpha,
    this.color = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 内阴影：用保存图层 + 模糊实现
    canvas.saveLayer(rect, Paint());
    canvas.drawRRect(
      rrect,
      Paint()..color = color.withOpacity(alpha),
    );
    // 用 dstIn 混合模式只保留边缘
    final innerRect = rect.deflate(2);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(radius - 2 > 0 ? radius - 2 : 0),
    );
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.white,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter old) =>
      old.radius != radius || old.alpha != alpha;
}

/// 液态玻璃容器
class LiquidGlassContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double displacementScale;
  final double aberration;
  final double edgeWidth;
  final double blurAmount;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool interactive;
  final bool enableInnerShadow;
  final bool enableDynamicHighlight;
  final bool enableRefraction;
  final double innerShadowAlpha;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.displacementScale = 25,
    this.aberration = 0.4,
    this.edgeWidth = 0.12,
    this.blurAmount = 8,
    this.padding,
    this.margin,
    this.onTap,
    this.interactive = true,
    this.enableInnerShadow = true,
    this.enableDynamicHighlight = true,
    this.enableRefraction = false,
    this.innerShadowAlpha = 0.15,
  });

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _timeController;

  // 动态高光
  double _tiltX = 0;
  double _tiltY = 0;
  void Function(double, double)? _sensorListener;

  @override
  void initState() {
    super.initState();
    // 只有启用折射时才启动动画控制器，避免不必要的持续重绘
    if (widget.enableRefraction) {
      _timeController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
      )..repeat();
      _loadProgram().then((p) {
        if (mounted) setState(() => _program = p);
      });
    } else {
      _timeController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      );
    }

    // 动态高光：监听传感器
    if (widget.enableDynamicHighlight) {
      _sensorListener = (x, y) {
        if (mounted) {
          setState(() {
            _tiltX = x;
            _tiltY = y;
          });
        }
      };
      SensorService().addListener(_sensorListener!);
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    if (_sensorListener != null) {
      SensorService().removeListener(_sensorListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 按压变形：按下时轻微放大
    final scale = _pressed ? 0.96 : (_hovered ? 1.02 : 1.0);
    final pressProgress = _pressed ? 1.0 : 0.0;

    // 动态高光位置
    final highlightX = 0.5 + _tiltX * 0.3;
    final highlightY = 0.3 + _tiltY * 0.2;

    // 玻璃内容层
    Widget glassContent = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          // 第1层：背景模糊
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: widget.blurAmount,
                sigmaY: widget.blurAmount,
              ),
              child: Container(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          // 第2层：shader 边缘折射彩虹
          if (widget.enableRefraction && _program != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _timeController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _GlassRefractionPainter(
                      shader: _program!.fragmentShader(),
                      displacementScale:
                          widget.displacementScale * (_hovered ? 1.3 : 1.0),
                      aberration: widget.aberration,
                      edgeWidth: widget.edgeWidth,
                      time: _timeController.value * 10,
                    ),
                  );
                },
              ),
            ),
          // 第3层：内阴影
          if (widget.enableInnerShadow)
            Positioned.fill(
              child: CustomPaint(
                painter: _InnerShadowPainter(
                  radius: widget.borderRadius,
                  alpha: widget.innerShadowAlpha * (0.5 + pressProgress * 0.5),
                ),
              ),
            ),
          // 第4层：动态高光（传感器驱动）
          if (widget.enableDynamicHighlight)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DynamicHighlightPainter(
                    x: highlightX,
                    y: highlightY,
                    radius: widget.borderRadius,
                    alpha: isDark ? 0.08 : 0.12,
                  ),
                ),
              ),
            ),
          // 第5层：内容
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child,
          ),
          // 第6层：悬停高光
          if (widget.interactive && _hovered)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 外层：边框 + 阴影
    Widget result = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.06),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -3,
          ),
        ],
      ),
      child: glassContent,
    );

    // 交互层
    if (widget.interactive) {
      result = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: result,
        ),
      );
    }

    return Container(
      margin: widget.margin,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: result,
      ),
    );
  }
}

/// 动态高光绘制器
class _DynamicHighlightPainter extends CustomPainter {
  final double x;
  final double y;
  final double radius;
  final double alpha;

  _DynamicHighlightPainter({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = RadialGradient(
      center: Alignment(
        (x - 0.5) * 2,
        (y - 0.5) * 2,
      ),
      radius: 0.8,
      colors: [
        Colors.white.withOpacity(alpha),
        Colors.white.withOpacity(alpha * 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(Offset.zero & size);
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _DynamicHighlightPainter old) =>
      old.x != x || old.y != y || old.alpha != alpha;
}

/// 玻璃胶囊底栏
class GlassPillBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassPillBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 999,
      displacementScale: 20,
      aberration: 0.35,
      edgeWidth: 0.15,
      blurAmount: 12,
      padding: padding,
      interactive: false,
      innerShadowAlpha: 0.1,
      child: child,
    );
  }
}

/// 玻璃圆形按钮
class GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;

  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        iconColor ?? (isDark ? Colors.white : const Color(0xFF007AFF));

    return LiquidGlassContainer(
      borderRadius: size / 2,
      displacementScale: 12,
      aberration: 0.2,
      edgeWidth: 0.15,
      blurAmount: 8,
      onTap: onPressed,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.45, color: color),
      ),
    );
  }
}

/// 玻璃胶囊按钮
class GlassPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const GlassPillButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LiquidGlassContainer(
      borderRadius: 999,
      displacementScale: 12,
      aberration: 0.2,
      edgeWidth: 0.12,
      blurAmount: 8,
      onTap: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF007AFF),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// 液态玻璃开关（参考 Kyant0 LiquidToggle）
class LiquidToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const LiquidToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  State<LiquidToggle> createState() => _LiquidToggleState();
}

class _LiquidToggleState extends State<LiquidToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(LiquidToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.animateTo(widget.value ? 1.0 : 0.0,
          curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.activeColor ??
        (isDark ? const Color(0xFF30D158) : const Color(0xFF34C759));
    final trackColor = isDark
        ? const Color(0xFF787880).withOpacity(0.36)
        : const Color(0xFF787878).withOpacity(0.2);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onChanged?.call(!widget.value);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final fraction = _controller.value;
          final thumbScale = _pressed ? 1.15 : 1.0;

          return Container(
            width: 52,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Color.lerp(trackColor, activeColor, fraction),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 玻璃滑块
                Transform.translate(
                  offset: Offset(
                    2 + fraction * 20,
                    0,
                  ),
                  child: Transform.scale(
                    scale: thumbScale,
                    child: LiquidGlassContainer(
                      borderRadius: 14,
                      displacementScale: 8,
                      aberration: 0.15,
                      edgeWidth: 0.1,
                      blurAmount: 6,
                      interactive: false,
                      enableInnerShadow: true,
                      innerShadowAlpha: 0.08,
                      padding: EdgeInsets.zero,
                      child: const SizedBox(width: 28, height: 28),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 液态玻璃组件 - BackdropFilter 模糊 + 自定义 shader 边缘折射
/// Flutter 3.24 兼容版本（无 AnimatedSampler）

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
    // uniform: 0,1=size, 2=displacementScale, 3=aberration, 4=edgeWidth, 5=time
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
  });

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  bool _hovered = false;
  bool _pressed = false;
  Offset _mousePos = Offset.zero;
  late final AnimationController _timeController;

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadProgram().then((p) {
      if (mounted) setState(() => _program = p);
    });
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = _pressed ? 0.97 : (_hovered ? 1.02 : 1.0);

    // 玻璃内容层
    Widget glassContent = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          // 第1层：背景模糊（填满）
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: widget.blurAmount,
                sigmaY: widget.blurAmount,
              ),
              child: Container(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          // 第2层：shader 边缘折射彩虹（填满）
          if (_program != null)
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
          // 第3层：内容（决定 Stack 尺寸）
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child,
          ),
          // 第4层：悬停高光
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

    // 第5层：动态高光边框（在 ClipRRect 外面，用 Container decoration）
    Widget result = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.35),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -3,
          ),
        ],
        gradient: _hovered
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.33, 0.66, 1.0],
              )
            : null,
      ),
      child: glassContent,
    );

    // 交互层
    if (widget.interactive) {
      result = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        onHover: (e) => setState(() => _mousePos = e.localPosition),
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

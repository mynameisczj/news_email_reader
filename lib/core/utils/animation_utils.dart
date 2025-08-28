import 'package:flutter/material.dart';

class AnimationUtils {
  // 动画持续时间常量
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);

  // 缓动曲线
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;

  /// 创建淡入动画
  static Widget fadeIn({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = defaultCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 创建滑入动画
  static Widget slideIn({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = defaultCurve,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 创建缩放动画
  static Widget scaleIn({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = defaultCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 创建旋转动画
  static Widget rotateIn({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = defaultCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 创建组合动画（淡入+滑入）
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = defaultCurve,
    Offset slideBegin = const Offset(0, 0.3),
    double fadeBegin = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: fadeBegin + (1.0 - fadeBegin) * value,
          child: Transform.translate(
            offset: Offset(
              slideBegin.dx * (1.0 - value),
              slideBegin.dy * (1.0 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// 创建弹性动画
  static Widget elasticIn({
    required Widget child,
    Duration duration = slowDuration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 创建波纹效果
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor?.withOpacity(0.3),
        highlightColor: rippleColor?.withOpacity(0.1),
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  /// 创建长按反馈动画
  static Widget pressAnimation({
    required Widget child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    double pressScale = 0.95,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _PressAnimationWidget(
      onTap: onTap,
      onLongPress: onLongPress,
      pressScale: pressScale,
      duration: duration,
      child: child,
    );
  }

  /// 创建列表项动画
  static Widget listItemAnimation({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 50),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: normalDuration + (delay * index),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// 创建页面转场动画
  static PageRouteBuilder createPageRoute({
    required Widget page,
    RouteSettings? settings,
    PageTransitionType type = PageTransitionType.slideFromRight,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case PageTransitionType.slideFromRight:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          case PageTransitionType.slideFromBottom:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          case PageTransitionType.fade:
            return FadeTransition(opacity: animation, child: child);
          case PageTransitionType.scale:
            return ScaleTransition(
              scale: animation.drive(
                Tween(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
        }
      },
    );
  }
}

enum PageTransitionType {
  slideFromRight,
  slideFromBottom,
  fade,
  scale,
}

class _PressAnimationWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final Duration duration;

  const _PressAnimationWidget({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.pressScale = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<_PressAnimationWidget> createState() => _PressAnimationWidgetState();
}

class _PressAnimationWidgetState extends State<_PressAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 自定义动画组件
class AnimatedCounter extends StatelessWidget {
  final int value;
  final Duration duration;
  final TextStyle? textStyle;

  const AnimatedCounter({
    Key? key,
    required this.value,
    this.duration = const Duration(milliseconds: 500),
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: textStyle,
        );
      },
    );
  }
}

/// 加载动画组件
class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;

  const LoadingAnimation({
    Key? key,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.14159,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.color ?? Theme.of(context).primaryColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
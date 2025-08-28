import 'package:flutter/material.dart';

/// 可滑动的邮件卡片组件
class SwipeableEmailCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? leftActionText;
  final String? rightActionText;
  final IconData? leftActionIcon;
  final IconData? rightActionIcon;
  final Color? leftActionColor;
  final Color? rightActionColor;

  const SwipeableEmailCard({
    Key? key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTap,
    this.onLongPress,
    this.leftActionText,
    this.rightActionText,
    this.leftActionIcon,
    this.rightActionIcon,
    this.leftActionColor,
    this.rightActionColor,
  }) : super(key: key);

  @override
  State<SwipeableEmailCard> createState() => _SwipeableEmailCardState();
}

class _SwipeableEmailCardState extends State<SwipeableEmailCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  
  double _dragExtent = 0.0;
  bool _dragUnderway = false;
  
  static const double _kSwipeThreshold = 0.4;
  static const double _kMaxSwipeExtent = 100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
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

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    _controller.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragUnderway) return;

    final delta = details.primaryDelta ?? 0.0;
    _dragExtent += delta;
    
    // 限制滑动范围
    _dragExtent = _dragExtent.clamp(-_kMaxSwipeExtent, _kMaxSwipeExtent);
    
    setState(() {
      _offsetAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(_dragExtent / context.size!.width, 0.0),
      ).animate(_controller);
    });
    
    _controller.value = 1.0;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragUnderway) return;
    _dragUnderway = false;

    final velocity = details.primaryVelocity ?? 0.0;
    final extent = _dragExtent.abs() / context.size!.width;
    
    if (extent >= _kSwipeThreshold || velocity.abs() > 1000) {
      // 触发滑动操作
      if (_dragExtent > 0) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
      _animateToComplete();
    } else {
      // 回弹到原位
      _animateToReset();
    }
  }

  void _animateToComplete() {
    _controller.animateTo(1.0).then((_) {
      _resetPosition();
    });
  }

  void _animateToReset() {
    _offsetAnimation = Tween<Offset>(
      begin: Offset(_dragExtent / context.size!.width, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.reset();
    _controller.forward().then((_) {
      _resetPosition();
    });
  }

  void _resetPosition() {
    setState(() {
      _dragExtent = 0.0;
      _offsetAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero,
      ).animate(_controller);
    });
    _controller.reset();
  }

  Widget _buildActionBackground() {
    if (_dragExtent == 0) return const SizedBox.shrink();
    
    final isLeftSwipe = _dragExtent < 0;
    final actionColor = isLeftSwipe 
        ? (widget.leftActionColor ?? Colors.red)
        : (widget.rightActionColor ?? Colors.green);
    final actionIcon = isLeftSwipe
        ? (widget.leftActionIcon ?? Icons.delete)
        : (widget.rightActionIcon ?? Icons.star);
    final actionText = isLeftSwipe
        ? (widget.leftActionText ?? '删除')
        : (widget.rightActionText ?? '收藏');

    return Container(
      color: actionColor,
      child: Align(
        alignment: isLeftSwipe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                actionIcon,
                color: Colors.white,
                size: 24.0,
              ),
              const SizedBox(height: 4.0),
              Text(
                actionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          _buildActionBackground(),
          AnimatedBuilder(
            animation: _offsetAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _offsetAnimation.value.dx * MediaQuery.of(context).size.width,
                  0.0,
                ),
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 下拉刷新组件
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const CustomRefreshIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).primaryColor,
      backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
      strokeWidth: 2.0,
      displacement: 60.0,
      child: child,
    );
  }
}

/// 可展开的邮件内容组件
class ExpandableContent extends StatefulWidget {
  final Widget header;
  final Widget content;
  final bool initiallyExpanded;
  final Duration animationDuration;

  const ExpandableContent({
    Key? key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<ExpandableContent> createState() => _ExpandableContentState();
}

class _ExpandableContentState extends State<ExpandableContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpansion,
          child: Row(
            children: [
              Expanded(child: widget.header),
              AnimatedBuilder(
                animation: _iconAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _iconAnimation.value * 3.14159,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 24.0,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: widget.content,
        ),
      ],
    );
  }
}

/// 浮动操作按钮组
class FloatingActionButtonGroup extends StatefulWidget {
  final List<FloatingActionButtonData> buttons;
  final IconData mainIcon;
  final VoidCallback? onMainPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FloatingActionButtonGroup({
    Key? key,
    required this.buttons,
    this.mainIcon = Icons.add,
    this.onMainPressed,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  State<FloatingActionButtonGroup> createState() => _FloatingActionButtonGroupState();
}

class _FloatingActionButtonGroupState extends State<FloatingActionButtonGroup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
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

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final button = entry.value;
          
          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  -60.0 * (index + 1) * _expandAnimation.value,
                ),
                child: Opacity(
                  opacity: _expandAnimation.value,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: 'fab_$index',
                    onPressed: button.onPressed,
                    backgroundColor: button.backgroundColor,
                    child: Icon(button.icon),
                  ),
                ),
              );
            },
          );
        }),
        FloatingActionButton(
          onPressed: widget.onMainPressed ?? _toggleExpansion,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * 3.14159,
                child: Icon(widget.mainIcon),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FloatingActionButtonData {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const FloatingActionButtonData({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
  });
}
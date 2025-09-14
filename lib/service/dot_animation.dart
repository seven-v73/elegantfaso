import 'package:flutter/material.dart';

class DotAnimation extends StatefulWidget {
  final double delay;

  const DotAnimation({super.key, required this.delay});

  @override
  State<DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<DotAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.delay, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
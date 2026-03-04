import 'package:flutter/material.dart';

class AnimatedDialog extends StatelessWidget {
  final Widget child;
  const AnimatedDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(
          opacity: ((value - 0.95) / 0.05).clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

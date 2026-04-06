import 'package:flutter/material.dart';

class MiniBarsSparkline extends StatelessWidget {
  final List<int> points;
  final Color? color;
  const MiniBarsSparkline({super.key, required this.points, this.color});

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    final maxVal = points.isEmpty ? 0 : (points.reduce((a, b) => a > b ? a : b));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final v in points)
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: maxVal == 0 ? 2 : (2 + (22 * (v / maxVal))).clamp(2, 22),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

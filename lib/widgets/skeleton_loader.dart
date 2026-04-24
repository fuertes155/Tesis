import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = context.radii;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? r.md),
        ),
      ),
    );
  }
}

class DashboardGridSkeleton extends StatelessWidget {
  const DashboardGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width > 900) {
          crossAxisCount = 3;
        } else if (width > 600) {
          crossAxisCount = 2;
        }

        final itemWidth =
            ((width - (crossAxisCount - 1) * s.lg) / crossAxisCount)
                .clamp(240.0, 520.0);

        return Wrap(
          spacing: s.lg,
          runSpacing: s.lg,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: itemWidth,
              child: AspectRatio(
                aspectRatio: 1.9,
                child: SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

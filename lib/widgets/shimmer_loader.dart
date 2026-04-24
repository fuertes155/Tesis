import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Shimmer de carga genérico para reemplazar CircularProgressIndicator.
///
/// Ejemplo:
/// ```dart
/// ShimmerBox(width: double.infinity, height: 80, radius: 16)
/// ShimmerList(itemCount: 5, itemHeight: 72)
/// ```
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 60,
    this.radius = 16,
    this.margin,
  });

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = isDark ? const Color(0xFF0F1F38) : const Color(0xFFE2EFF8);
    final highlight = isDark ? const Color(0xFF1A3050) : const Color(0xFFD0E5F5);

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        color: base,
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(_anim.value - 1, 0),
                  end: Alignment(_anim.value + 1, 0),
                  colors: [base, highlight, base],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

/// Lista de shimmer para pantallas de carga
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 80,
    this.radius = 16,
    this.padding,
  });

  final int itemCount;
  final double itemHeight;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: padding ?? EdgeInsets.all(spacing.lg),
      child: Column(
        children: List.generate(
          itemCount,
          (i) => ShimmerBox(
            width: double.infinity,
            height: itemHeight,
            radius: radius,
            margin: EdgeInsets.only(bottom: spacing.md),
          ),
        ),
      ),
    );
  }
}

/// Shimmer de KPI card (cuadrado)
class ShimmerKpi extends StatelessWidget {
  const ShimmerKpi({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: ShimmerBox(
            height: 110,
            radius: 20,
            margin: EdgeInsets.only(
              left: i == 0 ? 0 : spacing.md / 2,
              right: i == 2 ? 0 : spacing.md / 2,
            ),
          ),
        );
      }),
    );
  }
}

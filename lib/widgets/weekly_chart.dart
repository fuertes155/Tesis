import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Barras de sesiones por día de los últimos 7 días (la última barra es hoy).
/// No incluye tarjeta ni título: se coloca dentro de un [DashboardPanel].
class WeeklyChart extends StatelessWidget {
  final List<int> counts;
  final double height;

  const WeeklyChart({super.key, required this.counts, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final maxVal = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final labels = _last7DayLabels();

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < counts.length; i++)
            Expanded(
              child: _Barra(
                valor: counts[i],
                maximo: maxVal,
                etiqueta: i < labels.length ? labels[i] : '',
                esHoy: i == counts.length - 1,
              ),
            ),
        ],
      ),
    );
  }

  static List<String> _last7DayLabels() {
    const nombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--) nombres[now.subtract(Duration(days: i)).weekday - 1],
    ];
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.valor,
    required this.maximo,
    required this.etiqueta,
    required this.esHoy,
  });

  final int valor;
  final int maximo;
  final String etiqueta;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final alturaMax = constraints.maxHeight - 24;
              final alto = valor == 0 ? 4.0 : (alturaMax * valor / maximo).clamp(10.0, alturaMax);
              final ancho = (constraints.maxWidth * 0.56).clamp(12.0, 40.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    valor > 0 ? '$valor' : '',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: esHoy ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: alto),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, h, _) => Container(
                      width: ancho,
                      height: h,
                      decoration: BoxDecoration(
                        gradient: esHoy && valor > 0 ? context.glass.accentGradient : null,
                        color: esHoy && valor > 0
                            ? null
                            : valor == 0
                                ? cs.surfaceContainerHigh
                                : cs.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          esHoy ? 'Hoy' : etiqueta,
          style: theme.textTheme.labelMedium?.copyWith(
            color: esHoy ? cs.primary : cs.onSurfaceVariant,
            fontWeight: esHoy ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class WeeklyChartSkeleton extends StatelessWidget {
  const WeeklyChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const alturas = [60.0, 110.0, 80.0, 140.0, 70.0, 120.0, 90.0];
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in alturas)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 28,
                    height: h,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 22,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

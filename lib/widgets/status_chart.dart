import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Anillo con el porcentaje de sesiones completadas y leyenda de estados.
/// No incluye tarjeta ni título: se coloca dentro de un [DashboardPanel].
class StatusChart extends StatelessWidget {
  final int completed;
  final int pending;
  const StatusChart({super.key, required this.completed, required this.pending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sem = context.sem;
    final total = completed + pending;
    final pct = total == 0 ? 0 : (completed * 100 / total).round();

    return Row(
      children: [
        SizedBox(
          width: 124,
          height: 124,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: total == 0 ? 0 : completed / total),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, fraccion, _) => CustomPaint(
              painter: _AnilloPainter(
                fraccion: fraccion,
                colorCompletado: sem.success,
                colorPendiente: total == 0 ? cs.surfaceContainerHigh : sem.warning,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('completadas', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Leyenda(color: sem.success, etiqueta: 'Completadas', valor: completed),
              const SizedBox(height: 12),
              _Leyenda(color: sem.warning, etiqueta: 'Pendientes', valor: pending),
              const SizedBox(height: 12),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Total', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text('$total', style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.etiqueta, required this.valor});

  final Color color;
  final String etiqueta;
  final int valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(etiqueta, style: theme.textTheme.bodyMedium)),
        Text(
          '$valor',
          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _AnilloPainter extends CustomPainter {
  _AnilloPainter({
    required this.fraccion,
    required this.colorCompletado,
    required this.colorPendiente,
  });

  final double fraccion;
  final Color colorCompletado;
  final Color colorPendiente;

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 14.0;
    final rect = Rect.fromLTWH(
      grosor / 2,
      grosor / 2,
      size.width - grosor,
      size.height - grosor,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = colorPendiente.withValues(alpha: 0.9));
    if (fraccion > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * fraccion,
        false,
        base..color = colorCompletado,
      );
    }
  }

  @override
  bool shouldRepaint(_AnilloPainter old) =>
      old.fraccion != fraccion ||
      old.colorCompletado != colorCompletado ||
      old.colorPendiente != colorPendiente;
}

class StatusChartSkeleton extends StatelessWidget {
  const StatusChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.surfaceContainerHigh, width: 14),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

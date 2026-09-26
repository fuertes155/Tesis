import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'stat_card.dart';
import 'stat_skeleton.dart';
import '../core/theme/app_theme.dart';

class HomeKpiSection extends StatelessWidget {
  final bool loading;
  final int patientsCount;
  final int sessionsToday;
  final int sessionsPending;
  final int todayVsYesterdayPct;
  final int pendingWeekDeltaPct;
  final List<int> counts30;

  /// Sesiones por día de los últimos 7 días (la última es hoy).
  final List<int> weeklyCounts;

  const HomeKpiSection({
    super.key,
    required this.loading,
    required this.patientsCount,
    required this.sessionsToday,
    required this.sessionsPending,
    required this.todayVsYesterdayPct,
    required this.pendingWeekDeltaPct,
    required this.counts30,
    this.weeklyCounts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 980 ? 4 : 2;

        if (loading) {
          return _Filas(
            columnas: columnas,
            children: List.generate(
              4,
              (i) => SizedBox(
                height: 150,
                child: const StatSkeleton()
                    .animate()
                    .fadeIn(duration: 210.ms, delay: (i * 60).ms),
              ),
            ),
          );
        }

        final semana = weeklyCounts.fold<int>(0, (a, b) => a + b);
        final tendenciaHoy = todayVsYesterdayPct == 0
            ? null
            : '${todayVsYesterdayPct > 0 ? '+' : ''}$todayVsYesterdayPct%';

        final items = <Widget>[
          StatCard(
            title: 'Pacientes',
            value: '$patientsCount',
            caption: 'Registrados en el sistema',
            icon: Icons.people_alt_rounded,
            color: cs.primary,
          ),
          StatCard(
            title: 'Sesiones hoy',
            value: '$sessionsToday',
            caption: 'Comparado con ayer',
            icon: Icons.today_rounded,
            color: cs.secondary,
            trendText: tendenciaHoy,
            trendUp: todayVsYesterdayPct >= 0,
          ),
          StatCard(
            title: 'Pendientes',
            value: '$sessionsPending',
            caption: sessionsPending == 0 ? 'Todo al día' : 'Por completar',
            icon: Icons.pending_actions_rounded,
            color: context.sem.warning,
          ),
          StatCard(
            title: 'Esta semana',
            value: '$semana',
            caption: 'Sesiones en 7 días',
            icon: Icons.insights_rounded,
            color: cs.tertiary,
          ),
        ];

        return _Filas(
          columnas: columnas,
          children: [
            for (var i = 0; i < items.length; i++)
              items[i]
                  .animate()
                  .fadeIn(duration: 220.ms, delay: (i * 60).ms)
                  .moveY(begin: 8, end: 0, duration: 220.ms, delay: (i * 60).ms),
          ],
        );
      },
    );
  }
}

/// Reparte los hijos en filas de [columnas] con la misma altura por fila.
class _Filas extends StatelessWidget {
  const _Filas({required this.columnas, required this.children});

  final int columnas;
  final List<Widget> children;

  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < children.length; i += columnas) {
      final fila = children.sublist(i, (i + columnas).clamp(0, children.length));
      if (filas.isNotEmpty) filas.add(const SizedBox(height: _gap));
      filas.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columnas; j++) ...[
                if (j > 0) const SizedBox(width: _gap),
                Expanded(child: j < fila.length ? fila[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: filas);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'stat_card.dart';
import 'stat_skeleton.dart';

class HomeKpiSection extends StatelessWidget {
  final bool loading;
  final int patientsCount;
  final int sessionsToday;
  final int sessionsPending;
  final int todayVsYesterdayPct;
  final int pendingWeekDeltaPct;
  final List<int> counts30;

  const HomeKpiSection({
    super.key,
    required this.loading,
    required this.patientsCount,
    required this.sessionsToday,
    required this.sessionsPending,
    required this.todayVsYesterdayPct,
    required this.pendingWeekDeltaPct,
    required this.counts30,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width > 800) {
          crossAxisCount = 3;
        } else if (width > 500) {
          crossAxisCount = 2;
        }
        // signed() no longer needed (se removieron trends)

        if (loading) {
          final extent = width > 800
              ? 180.0
              : width > 500
              ? 200.0
              : 220.0;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: extent,
            ),
            itemCount: 3,
            itemBuilder: (context, i) => const StatSkeleton()
                .animate()
                .fadeIn(duration: 210.ms, delay: (i * 60).ms)
                .moveY(begin: 6, end: 0, duration: 210.ms, delay: (i * 60).ms),
          );
        }

        final items = [
          StatCard(
            title: 'Pacientes',
            value: '$patientsCount',
            icon: Icons.people_alt_outlined,
            color: theme.colorScheme.secondary,
          ),
          StatCard(
            title: 'Sesiones hoy',
            value: '$sessionsToday',
            icon: Icons.today_outlined,
            color: theme.colorScheme.primary,
          ),
          StatCard(
            title: 'Pendientes',
            value: '$sessionsPending',
            icon: Icons.pending_actions_outlined,
            color: theme.colorScheme.tertiary,
          ),
        ];

        final extent = width > 800
            ? 220.0
            : width > 500
            ? 240.0
            : 260.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: extent,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => items[i]
              .animate()
              .fadeIn(duration: 160.ms, delay: (i * 60).ms)
              .moveY(begin: 6, end: 0, duration: 160.ms, delay: (i * 60).ms),
        );
      },
    );
  }
}

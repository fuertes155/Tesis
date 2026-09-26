import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'recent_activity_card.dart';
import 'recent_activity_skeleton.dart';
import '../core/theme/app_theme.dart';
import '../models/session.dart';

class HomeRecentActivitySection extends StatelessWidget {
  final bool loading;
  final List<Session> sessions;
  final Map<int, String> patientNames;
  final Future<void> Function(Session s) onTapSession;

  const HomeRecentActivitySection({
    super.key,
    required this.loading,
    required this.sessions,
    required this.patientNames,
    required this.onTapSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sem = context.sem;

    if (loading) {
      return Column(
        children: List.generate(
          3,
          (i) => const RecentActivitySkeleton()
              .animate()
              .fadeIn(duration: 220.ms, delay: (i * 80).ms),
        ),
      );
    }

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            Text('Sin actividad para estos filtros', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text('Prueba con otro rango de fechas o estado.', style: theme.textTheme.bodySmall),
          ],
        ),
      ).animate().fadeIn(duration: 220.ms);
    }

    return Column(
      children: [
        for (var i = 0; i < sessions.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 62, color: cs.outlineVariant.withValues(alpha: 0.7)),
          Builder(
            builder: (context) {
              final s = sessions[i];
              final name = patientNames[s.patientId] ?? 'Paciente #${s.patientId}';
              final estado = s.status.toLowerCase();
              final completada = estado == 'completed' || estado == 'completada';
              return RecentActivityCard(
                patientName: name,
                action: completada ? 'Completada' : 'En progreso',
                time: DateFormat("d MMM · HH:mm", 'es').format(s.date),
                icon: completada ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                color: completada ? sem.success : sem.warning,
                onTap: () => onTapSession(s),
              )
                  .animate()
                  .fadeIn(duration: 220.ms, delay: (i * 60).ms)
                  .moveY(begin: 6, end: 0, duration: 220.ms, delay: (i * 60).ms);
            },
          ),
        ],
      ],
    );
  }
}

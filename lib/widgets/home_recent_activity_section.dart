import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'recent_activity_card.dart';
import 'recent_activity_skeleton.dart';
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
    if (loading) {
      return Column(
        children: List.generate(
          3,
          (i) => const RecentActivitySkeleton()
              .animate()
              .fadeIn(duration: 220.ms, delay: (i * 80).ms)
              .moveY(
                begin: 6,
                end: 0,
                duration: 220.ms,
                delay: (i * 80).ms,
              ),
        ),
      );
    }
    if (sessions.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('No hay actividad reciente'),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 220.ms)
          .moveY(begin: 6, end: 0, duration: 220.ms);
    }
    return Column(
      children: List.generate(sessions.length, (i) {
        final s = sessions[i];
        final pid = s.patientId;
        final name = patientNames[pid] ?? 'Paciente #$pid';
        final status = s.status;
        final date = s.date;
        final isCompleted =
            status.toLowerCase() == 'completed' || status.toLowerCase() == 'completada';
        final icon =
            isCompleted ? Icons.check_circle_outline : Icons.pending_outlined;
        final color = isCompleted ? Colors.green : Colors.orange;
        final action =
            isCompleted ? 'Evaluación completada' : 'Sesión en progreso';
        final time = DateFormat('dd/MM HH:mm').format(date);
        return RecentActivityCard(
              patientName: name,
              action: action,
              time: time,
              icon: icon,
              color: color,
              onTap: () => onTapSession(s),
            )
            .animate()
            .fadeIn(duration: 220.ms, delay: (i * 80).ms)
            .moveY(
              begin: 6,
              end: 0,
              duration: 220.ms,
              delay: (i * 80).ms,
            );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/api_providers.dart';

class NewSessionScreen extends ConsumerWidget {
  final int? patientId;

  const NewSessionScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;

    // Use unawaited if possible, but for a build method we just read the value if available
    final apiValue = ref.read(apiServiceProvider).value;
    if (patientId != null && apiValue != null) {
      apiValue.setCurrentPatientId(patientId!);
    }

    final batteries = [
      _Battery(
        title: 'Protocolo Integral',
        description: 'Evaluación completa de funciones cognitivas principales.',
        icon: Icons.psychology_outlined,
        tag: 'Recomendado',
        color: cs.primary,
        durationLabel: '~26 min',
        isPrimary: true,
        onTap: () => context.push('/test_selector'),
      ),
      _Battery(
        title: 'Atención y Memoria',
        description: 'Enfoque específico en retención y procesos atencionales.',
        icon: Icons.memory_outlined,
        tag: 'Especializado',
        color: cs.tertiary,
        durationLabel: '~14 min',
        isPrimary: false,
        onTap: () => context.push('/test_selector'),
      ),
      _Battery(
        title: 'Screening Rápido',
        description: 'Evaluación breve para detección temprana.',
        icon: Icons.speed_outlined,
        tag: 'Rápido',
        color: cs.secondary,
        durationLabel: '~8 min',
        isPrimary: false,
        onTap: () => context.push('/test_selector'),
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: cs.surfaceContainerLowest,
            surfaceTintColor: cs.surfaceContainerLowest,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NUEVA SESIÓN',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Seleccionar Batería',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sub-header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
              child: Text(
                'Elija el protocolo de evaluación para este paciente. Puede personalizar las pruebas después de seleccionar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),

          // ── Baterías ──────────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.all(spacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final b = batteries[index];
                  return _BatteryCard(battery: b)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 100 + index * 80))
                      .slideY(begin: 0.08);
                },
                childCount: batteries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Battery {
  final String title;
  final String description;
  final IconData icon;
  final String tag;
  final Color color;
  final String durationLabel;
  final bool isPrimary;
  final VoidCallback onTap;

  const _Battery({
    required this.title,
    required this.description,
    required this.icon,
    required this.tag,
    required this.color,
    required this.durationLabel,
    required this.isPrimary,
    required this.onTap,
  });
}

class _BatteryCard extends StatelessWidget {
  final _Battery battery;
  const _BatteryCard({required this.battery});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final r = context.radii;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.md),
      child: Material(
        color: battery.isPrimary ? battery.color : cs.surfaceContainerLowest,
        borderRadius: r.radiusLg,
        child: InkWell(
          onTap: battery.onTap,
          borderRadius: r.radiusLg,
          child: Container(
            padding: EdgeInsets.all(spacing.lg),
            decoration: BoxDecoration(
              borderRadius: r.radiusLg,
              border: battery.isPrimary
                  ? null
                  : Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                // Icono
                Container(
                  padding: EdgeInsets.all(spacing.md),
                  decoration: BoxDecoration(
                    color: battery.isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : battery.color.withValues(alpha: 0.1),
                    borderRadius: r.radiusMd,
                  ),
                  child: Icon(
                    battery.icon,
                    color: battery.isPrimary ? Colors.white : battery.color,
                    size: 28,
                  ),
                ),
                SizedBox(width: spacing.lg),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              battery.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: battery.isPrimary ? Colors.white : cs.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: battery.isPrimary
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : battery.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              battery.tag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: battery.isPrimary ? Colors.white : battery.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.xs - 2),
                      Text(
                        battery.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: battery.isPrimary
                              ? Colors.white.withValues(alpha: 0.8)
                              : cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: battery.isPrimary
                                ? Colors.white.withValues(alpha: 0.7)
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            battery.durationLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: battery.isPrimary
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.sm),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: battery.isPrimary
                      ? Colors.white.withValues(alpha: 0.7)
                      : cs.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

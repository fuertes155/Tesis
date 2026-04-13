import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../core/theme/app_theme.dart';

class NewSessionScreen extends StatelessWidget {
  final int? patientId;

  const NewSessionScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    
    if (patientId != null) {
      GetIt.I<ApiService>().setCurrentPatientId(patientId!);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        title: Text(
          'Nueva Sesión',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          SizedBox(height: spacing.md),
          Text(
            'SELECCIONE BATERÍA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            'Elija el protocolo de evaluación que desea aplicar al paciente.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.xl),
          _BatteryCard(
            title: 'Protocolo Integral',
            description:
                'Evaluación completa de funciones cognitivas principales.',
            icon: Icons.psychology_outlined,
            color: cs.primary,
            onTap: () => context.push('/test_selector'),
          ),
          SizedBox(height: spacing.md),
          _BatteryCard(
            title: 'Atención y Memoria',
            description:
                'Enfoque específico en retención y procesos atencionales.',
            icon: Icons.memory_outlined,
            color: cs.onSurface,
            onTap: () => context.push('/test_selector'),
          ),
          SizedBox(height: spacing.md),
          _BatteryCard(
            title: 'Screening Rápido',
            description: 'Evaluación breve para detección temprana.',
            icon: Icons.speed_outlined,
            color: cs.onSurfaceVariant,
            onTap: () => context.push('/test_selector'),
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BatteryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: r.radiusLg,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: r.radiusLg,
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.md),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: r.radiusMd,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                SizedBox(width: spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: spacing.xs - 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.sm),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: cs.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Fila de actividad reciente: avatar del paciente, fecha y estado de la sesión.
class RecentActivityCard extends StatelessWidget {
  final String patientName;

  /// Estado de la sesión, p. ej. "Completada".
  final String action;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const RecentActivityCard({
    super.key,
    required this.patientName,
    required this.action,
    required this.time,
    required this.icon,
    required this.color,
    this.onTap,
  });

  static const _coloresAvatar = [
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFD97706),
    Color(0xFF0891B2),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colorAvatar = _coloresAvatar[patientName.hashCode.abs() % _coloresAvatar.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radii.radiusMd,
        hoverColor: cs.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorAvatar.withValues(alpha: 0.14),
                child: Text(
                  _iniciales(patientName),
                  style: theme.textTheme.labelLarge?.copyWith(color: colorAvatar),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(time, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          action,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  static String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty && !p.startsWith('#'));
    final letras = partes.take(2).map((p) => p[0].toUpperCase()).join();
    return letras.isEmpty ? '?' : letras;
  }
}

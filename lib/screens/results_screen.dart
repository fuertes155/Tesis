import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/domain_result_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_service.dart';
import '../providers/api_providers.dart';
import '../widgets/empty_state_view.dart';

class ResultsScreen extends ConsumerWidget {
  final Map<String, dynamic>? data;
  final Future<Map<String, dynamic>>? dataFuture;
  const ResultsScreen({super.key, this.data, this.dataFuture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final sem = context.sem;

    if (dataFuture != null) {
      return FutureBuilder<Map<String, dynamic>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // ... (Skeleton UI)
            return _buildSkeletonScaffold(context, theme, spacing, cs);
          }
          if (snapshot.hasError) {
            // ... (Error UI)
            return _buildErrorScaffold(context, theme, spacing, cs, sem);
          }
          return ResultsScreen(data: snapshot.data);
        },
      );
    }
    
    final title = data?['title'] as String? ?? 'Resultados';
    final globalScore = (data?['score'] as num?)?.toDouble() ?? 0.0;
    final highGlobal = globalScore >= 90;
    final details = data?['details'] as Map<String, dynamic>? ?? {};
    final isHighScore = globalScore >= 90;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_outlined, color: cs.primary),
            onPressed: () async {
              final api = ref.read(apiServiceProvider).value;
              final pName = data?['patientName'] ?? api?.currentPatientName ?? 'Paciente';
              final pId = data?['patientId']?.toString() ?? api?.currentPatientId.toString();
              
              await PdfService.generateResultsPdf(
                patientName: pName,
                patientId: pId,
                title: title,
                score: globalScore,
                details: details,
              );
            },
            tooltip: 'Exportar PDF',
          ),
          SizedBox(width: spacing.md),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.xl),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: r.radiusXl,
                border: Border.all(
                  color: isHighScore
                      ? sem.success.withValues(alpha: 0.4)
                      : cs.outlineVariant,
                  width: isHighScore ? 2 : 1,
                ),
                boxShadow: isHighScore
                    ? [
                        BoxShadow(
                          color: sem.success.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: globalScore / 100,
                          strokeWidth: 14,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            highGlobal ? sem.success : cs.primary,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${globalScore.toInt()}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: highGlobal ? sem.success : cs.onSurface,
                              letterSpacing: -2,
                            ),
                          ),
                          Text(
                            'pts',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate(onPlay: isHighScore ? (c) => c.repeat(reverse: true) : null)
                    .shimmer(
                      duration: 2000.ms,
                      color: isHighScore
                          ? sem.success.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                  SizedBox(height: spacing.xl),
                  if (isHighScore)
                    FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_rounded, color: sem.success, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'RENDIMIENTO SOBRESALIENTE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: sem.success,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'PUNTUACIÓN GLOBAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  SizedBox(height: spacing.sm),
                  Text(
                    highGlobal ? 'Rendimiento Superior' : 'Rendimiento Estándar',
                    style: TextStyle(
                      color: highGlobal ? sem.success : cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(delay: 100.ms),
            SizedBox(height: spacing.x2l),
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: cs.primary, size: 20),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'DETALLE POR DOMINIOS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
            SizedBox(height: spacing.lg),
            ...details.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final detail = entry.value;
              final score = (detail.value as num?)?.toInt() ?? 50;
              final status = score >= 80
                  ? ResultStatus.normal
                  : score >= 60
                  ? ResultStatus.warning
                  : ResultStatus.critical;

              return Padding(
                padding: EdgeInsets.only(bottom: spacing.md),
                child:
                    DomainResultCard(
                          domain: detail.key,
                          score: score,
                          status: status,
                          icon: _domainIcon(detail.key),
                        )
                        .animate()
                        .fadeIn(delay: (400 + idx * 50).ms)
                        .slideX(begin: 0.1),
              );
            }),
            SizedBox(height: spacing.xl),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('VOLVER AL PANEL PRINCIPAL'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: r.radiusMd,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonScaffold(BuildContext context, ThemeData theme, AppSpacing spacing, ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        title: Text(
          'Cargando...',
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlobalSkeleton(theme)
                .animate()
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .moveY(begin: 8, end: 0, duration: 260.ms),
            SizedBox(height: spacing.x2l),
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: cs.primary, size: 20),
                SizedBox(width: spacing.sm),
                Text(
                  'DETALLE POR DOMINIOS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.lg),
            ..._buildSkeletonCards(theme, 4).asMap().entries.map(
                  (e) => e.value.animate().fadeIn(duration: 220.ms, delay: (60 * e.key).ms, curve: Curves.easeOut),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, ThemeData theme, AppSpacing spacing, ColorScheme cs, AppSemanticColors sem) {
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        title: const Text('Error'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: EmptyStateView(
            title: 'Error al cargar',
            description: 'No pudimos recuperar los resultados de esta sesión.',
            iconData: Icons.error_outline_rounded,
            buttonLabel: 'Reintentar',
            onButtonPressed: () => context.go('/home'),
          ),
        ),
      ),
    );
  }

  IconData _domainIcon(String domain) {
    switch (domain.toLowerCase()) {
      case 'memoria':
        return Icons.psychology_outlined;
      case 'atención':
        return Icons.visibility_outlined;
      case 'lenguaje':
        return Icons.record_voice_over_outlined;
      case 'funciones ejecutivas':
        return Icons.settings_suggest_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  Widget _buildGlobalSkeleton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
          ).animate().shimmer(
            duration: 900.ms,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ).animate().shimmer(
                duration: 900.ms,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ).animate().shimmer(
                duration: 900.ms,
                delay: 80.ms,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 16,
            width: 280,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
          ).animate().shimmer(
            duration: 900.ms,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkeletonCards(ThemeData theme, int count) {
    return List.generate(
      count,
      (i) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).animate().shimmer(
                  duration: 900.ms,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 140,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ).animate().shimmer(
                        duration: 900.ms,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 180,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ).animate().shimmer(
                        duration: 900.ms,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 24,
                  width: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ).animate().shimmer(
                  duration: 900.ms,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ).animate().shimmer(
              duration: 900.ms,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ],
        ),
      ),
    );
  }
}

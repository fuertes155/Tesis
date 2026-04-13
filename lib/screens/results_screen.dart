import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/domain_result_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Future<Map<String, dynamic>>? dataFuture;
  const ResultsScreen({super.key, this.data, this.dataFuture});

  @override
  Widget build(BuildContext context) {
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
            return Scaffold(
              backgroundColor: cs.surface,
              appBar: AppBar(
                backgroundColor: cs.surfaceContainerLowest,
                surfaceTintColor: cs.surfaceContainerLowest,
                elevation: 0,
                title: Text(
                  'Resultados',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
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
                        Icon(
                          Icons.analytics_outlined,
                          color: cs.primary,
                          size: 20,
                        ),
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
                      (e) => e.value
                          .animate()
                          .fadeIn(
                            duration: 220.ms,
                            delay: (60 * e.key).ms,
                            curve: Curves.easeOut,
                          )
                          .moveY(
                            begin: 6,
                            end: 0,
                            duration: 220.ms,
                            delay: (60 * e.key).ms,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: cs.surface,
              appBar: AppBar(
                backgroundColor: cs.surfaceContainerLowest,
                title: const Text('Resultados'),
                elevation: 0,
              ),
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Text(
                    'Error al cargar resultados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: sem.danger,
                    ),
                  ),
                ),
              ),
            );
          }
          return ResultsScreen(data: snapshot.data);
        },
      );
    }
    
    final title = data?['title'] as String? ?? 'Resultados';
    final globalScore = (data?['score'] as num?)?.toDouble();
    final highGlobal = (globalScore ?? 75) >= 90;
    final details = data?['details'] as Map<String, dynamic>? ?? {};

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
            icon: Icon(Icons.share_outlined, color: cs.onSurfaceVariant),
            onPressed: () {},
            tooltip: 'Compartir Informe',
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
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: (globalScore ?? 75) / 100,
                          strokeWidth: 12,
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
                            '${(globalScore ?? 75).toInt()}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                              letterSpacing: -2,
                            ),
                          ),
                          Text(
                            'Puntos',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xl),
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
                    highGlobal
                        ? 'Rendimiento Superior'
                        : 'Rendimiento Estándar',
                    style: TextStyle(
                      color: highGlobal
                          ? sem.success
                          : cs.primary,
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
                Text(
                  'DETALLE POR DOMINIOS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
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
              height: 54,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: r.radiusSm,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                child: const Text('FINALIZAR Y VOLVER AL INICIO'),
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/domain_result_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Future<Map<String, dynamic>>? dataFuture;
  const ResultsScreen({super.key, this.data, this.dataFuture});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A237E);
    if (dataFuture != null) {
      return FutureBuilder<Map<String, dynamic>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            final theme = Theme.of(context);
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'Resultados',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                centerTitle: false,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGlobalSkeleton(theme)
                        .animate()
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                        .moveY(begin: 8, end: 0, duration: 260.ms),
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'DETALLE POR DOMINIOS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
            final theme = Theme.of(context);
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: const Text('Resultados'),
                elevation: 0,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar resultados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFEF4444),
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
    final theme = Theme.of(context);
    final title = data?['title'] as String? ?? 'Resultados';
    final globalScore = (data?['score'] as num?)?.toDouble();
    final highGlobal = (globalScore ?? 75) >= 90;
    final details = data?['details'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
            onPressed: () {},
            tooltip: 'Compartir Informe',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            highGlobal ? const Color(0xFF10B981) : primaryColor,
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
                              color: const Color(0xFF1E293B),
                              letterSpacing: -2,
                            ),
                          ),
                          const Text(
                            'Puntos',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'PUNTUACIÓN GLOBAL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    highGlobal
                        ? 'Rendimiento Superior'
                        : 'Rendimiento Estándar',
                    style: TextStyle(
                      color: highGlobal
                          ? const Color(0xFF10B981)
                          : primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(delay: 100.ms),
            const SizedBox(height: 48),
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  'DETALLE POR DOMINIOS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
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
                padding: const EdgeInsets.only(bottom: 16),
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
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

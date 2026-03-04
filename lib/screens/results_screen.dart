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
    if (dataFuture != null) {
      return FutureBuilder<Map<String, dynamic>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            final theme = Theme.of(context);
            return Scaffold(
              backgroundColor: theme.colorScheme.surface,
              appBar: AppBar(
                title: const Text('Resultados'),
                centerTitle: true,
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
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Detalle por Dominios',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
              backgroundColor: theme.colorScheme.surface,
              appBar: AppBar(title: const Text('Resultados')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar resultados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
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
    final pulseGlobal = (globalScore ?? 75) >= 95;
    final isLoading = (data?['loading'] as bool?) ?? false;
    final details = data?['details'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => context.push('/report_preview'),
            tooltip: 'Ver Informe',
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
            tooltip: 'Ir a Inicio',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              _buildGlobalSkeleton(theme)
                  .animate()
                  .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                  .moveY(begin: 8, end: 0, duration: 260.ms),
            if (!isLoading)
              Container(
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
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: highGlobal ? 0.12 : 0.06,
                          ),
                          blurRadius: highGlobal ? 36 : 28,
                          offset: const Offset(0, 10),
                        ),
                        if (highGlobal)
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 48,
                            spreadRadius: 4,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Puntuación Global',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: (globalScore ?? 75) / 100,
                          ),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(
                                            alpha:
                                                0.15 +
                                                (highGlobal
                                                    ? (value * 0.15)
                                                    : 0),
                                          ),
                                      blurRadius:
                                          40 + (highGlobal ? (20 * value) : 0),
                                      spreadRadius:
                                          8 + (highGlobal ? (4 * value) : 0),
                                    ),
                                  ],
                                  gradient: SweepGradient(
                                    colors: [
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      theme.colorScheme.primary,
                                    ],
                                    stops: const [0.0, 1.0],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: CircularProgressIndicator(
                                  value: value.clamp(0, 1),
                                  strokeWidth: 16,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                        (globalScore ?? 75).toInt().toString(),
                                        style: theme.textTheme.displayLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                      )
                                      .animate(target: pulseGlobal ? 1 : 0)
                                      .scale(
                                        duration: 200.ms,
                                        curve: Curves.easeOut,
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.06, 1.06),
                                      ),
                                  Text(
                                    'Normal',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'El paciente presenta un desempeño general dentro del rango esperado para su edad y nivel educativo.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .moveY(begin: 10, end: 0, duration: 300.ms),
            const SizedBox(height: 32),

            // Domains Header
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Detalle por Dominios',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
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
              )
            else
              ..._buildDomainCards(details, theme).asMap().entries.map(
                (e) => e.value
                    .animate()
                    .fadeIn(
                      duration: 240.ms,
                      delay: (80 * e.key).ms,
                      curve: Curves.easeOut,
                    )
                    .moveY(
                      begin: 8,
                      end: 0,
                      duration: 240.ms,
                      delay: (80 * e.key).ms,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDomainCards(
    Map<String, dynamic> details,
    ThemeData theme,
  ) {
    if (details.isEmpty) {
      return [
        DomainResultCard(
          domain: 'Memoria',
          score: 85,
          status: ResultStatus.normal,
          icon: Icons.psychology_outlined,
        ),
        DomainResultCard(
          domain: 'Atención',
          score: 60,
          status: ResultStatus.warning,
          icon: Icons.visibility_outlined,
        ),
        DomainResultCard(
          domain: 'Lenguaje',
          score: 90,
          status: ResultStatus.normal,
          icon: Icons.record_voice_over_outlined,
        ),
        DomainResultCard(
          domain: 'Funciones Ejecutivas',
          score: 40,
          status: ResultStatus.critical,
          icon: Icons.settings_suggest_outlined,
        ),
      ];
    }
    final items = <Widget>[];
    details.forEach((domain, value) {
      final score = (value as num?)?.toInt() ?? 50;
      final status = score >= 80
          ? ResultStatus.normal
          : score >= 60
          ? ResultStatus.warning
          : ResultStatus.critical;
      final icon = _domainIcon(domain);
      items.add(
        DomainResultCard(
          domain: domain,
          score: score,
          status: status,
          icon: icon,
        ),
      );
    });
    return items;
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

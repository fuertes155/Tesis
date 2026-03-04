import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ResultStatus { normal, warning, critical }

class DomainResultCard extends StatelessWidget {
  final String domain;
  final int score;
  final ResultStatus status;
  final IconData icon;

  const DomainResultCard({
    super.key,
    required this.domain,
    required this.score,
    required this.status,
    required this.icon,
  });

  Color get _color {
    switch (status) {
      case ResultStatus.normal:
        return Colors.green;
      case ResultStatus.warning:
        return Colors.orange;
      case ResultStatus.critical:
        return Colors.red;
    }
  }

  String get _statusText {
    switch (status) {
      case ResultStatus.normal:
        return 'Normal';
      case ResultStatus.warning:
        return 'Riesgo Leve';
      case ResultStatus.critical:
        return 'Déficit';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highScore = score >= 80;
    final card = Container(
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Puntuación: $score/100',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _color.withValues(alpha: 0.24)),
                ),
                child: Text(
                  _statusText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOut,
            builder: (context, value, _) => Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (highScore)
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      opacity: highScore ? 1 : 0,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _color.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      colors: [_color.withValues(alpha: 0.85), _color],
                    ).createShader(rect),
                    blendMode: BlendMode.srcATop,
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return card
        .animate()
        .fadeIn(duration: 240.ms, curve: Curves.easeOut)
        .moveY(begin: 6, end: 0, duration: 240.ms, curve: Curves.easeOut)
        .animate(target: highScore ? 1 : 0)
        .shimmer(
          duration: 1400.ms,
          delay: 80.ms,
          color: Colors.white.withValues(alpha: 0.05),
        );
  }
}

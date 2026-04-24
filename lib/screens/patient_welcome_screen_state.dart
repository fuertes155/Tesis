part of 'patient_welcome_screen.dart';

class PatientWelcomeScreenState extends State<PatientWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final accepted = prefs.getBool('consent_accepted') ?? false;
      if (!mounted) return;
      if (accepted) {
        context.go('/test_selector');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final glass = context.glass;

    final steps = [
      _StepItem(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Consentimiento',
        description: 'Lectura y aceptación del consentimiento informado.',
        gradientColors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
      ),
      _StepItem(
        icon: Icons.ads_click_rounded,
        title: 'Pruebas Interactivas',
        description: 'Serie de evaluaciones cognitivas guiadas paso a paso.',
        gradientColors: [cs.tertiary, cs.tertiary.withValues(alpha: 0.7)],
      ),
      _StepItem(
        icon: Icons.timer_outlined,
        title: 'Duración Estimada',
        description: 'El proceso completo toma entre 15 y 20 minutos.',
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header Premium ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _WelcomeHero(),
          ),

          // ── Card flotante sobre el hero ────────────────────────────────────
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: glass.cardGradient,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: glass.borderColor, width: 1),
                    boxShadow: context.premiumShadows,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label superior
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 12,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'CÓMO FUNCIONA',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms),

                        SizedBox(height: spacing.xl),

                        // Steps
                        ...steps.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final step = entry.value;
                          return _buildStep(
                            context,
                            number: idx + 1,
                            step: step,
                            isLast: idx == steps.length - 1,
                            delay: Duration(milliseconds: 450 + idx * 100),
                          );
                        }),

                        SizedBox(height: spacing.xl),

                        // Divisor decorativo
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      cs.outlineVariant,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: cs.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.outlineVariant,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 700.ms),

                        SizedBox(height: spacing.xl),

                        // Botón principal — PremiumButton
                        SizedBox(
                          width: double.infinity,
                          child: PremiumButton(
                            label: 'COMENZAR AHORA',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final accepted =
                                  prefs.getBool('consent_accepted') ?? false;
                              if (!context.mounted) return;
                              if (accepted) {
                                context.go('/test_selector');
                              } else {
                                context.go('/consent');
                              }
                            },
                          ),
                        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.15),

                        SizedBox(height: spacing.md),

                        // Reset consentimiento
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('consent_accepted');
                              messenger.clearSnackBars();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Consentimiento restablecido'),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.refresh_rounded,
                              size: 15,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            label: Text(
                              'Restablecer Consentimiento',
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 900.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int number,
    required _StepItem step,
    required bool isLast,
    required Duration delay,
  }) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: ícono + línea
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: step.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: step.gradientColors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(step.icon, color: Colors.white, size: 22),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      step.gradientColors.first.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),

        SizedBox(width: spacing.lg),

        // Contenido
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: step.gradientColors.first.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: step.gradientColors.first.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: step.gradientColors.first,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: delay).slideX(begin: 0.06);
  }
}

// ── Welcome Hero ────────────────────────────────────────────────────────────────

class _WelcomeHero extends StatefulWidget {
  @override
  State<_WelcomeHero> createState() => _WelcomeHeroState();
}

class _WelcomeHeroState extends State<_WelcomeHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final glass = context.glass;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: glass.headerGradient),
      child: Stack(
        children: [
          // Orbes animados
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              return Stack(
                children: [
                  Positioned(
                    right: -40 + 30 * math.sin(t * 2 * math.pi),
                    top: 20 + 20 * math.cos(t * 2 * math.pi),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            cs.tertiary.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30 + 20 * math.sin(t * 2 * math.pi + 1),
                    bottom: 0,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Contenido
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.x2l,
                spacing.lg,
                spacing.x2l + 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícono central
                  Container(
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.06),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      size: 52,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(curve: Curves.easeOutBack),

                  SizedBox(height: spacing.xl),

                  Text(
                    'Evaluación\nCognitiva',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                      height: 1.05,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideX(begin: -0.08),

                  SizedBox(height: spacing.md),

                  Text(
                    'NeuroApp le guiará a través de una serie de\npruebas diseñadas para evaluar sus funciones\ncognitivas de forma precisa y segura.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.80),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms)
                      .slideY(begin: 0.08),

                  SizedBox(height: spacing.xl),

                  // Tags de características
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroChip(
                        icon: Icons.security_outlined,
                        label: 'Confidencial',
                      ),
                      _HeroChip(
                        icon: Icons.timer_outlined,
                        label: '15–20 min',
                      ),
                      _HeroChip(
                        icon: Icons.verified_outlined,
                        label: 'Clínicamente validado',
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _StepItem {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  const _StepItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}

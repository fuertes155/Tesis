part of 'login_screen.dart';

class LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    HapticFeedback.mediumImpact();
    await _login();
  }

  void _navigateBasedOnRole(String role) {
    if (role == 'doctor') {
      context.go('/home');
    } else if (role == 'gestor') {
      context.go('/users_admin');
    } else {
      context.go('/patient_welcome');
    }
  }

  Future<void> _login() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Ingresa usuario y contraseña');
      }
      final api = await ref.read(apiServiceProvider.future);
      final authData = await api.login(username, password);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      
      final bool mfaRequired = authData['mfa_required'] ?? false;
      if (mfaRequired) {
        context.go('/mfa');
      } else {
        _navigateBasedOnRole(api.currentRole ?? 'doctor');
      }
    } catch (e) {
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;

    return Scaffold(
      backgroundColor: cs.surface,
      body: AppDecorations.meshBackground(
        child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          if (isWide) {
            return Row(
              children: [
                // ── Left Branding Panel ──────────────────────────────────
                Expanded(
                  flex: 5,
                  child: _BrandingPanel(),
                ),
                // ── Right Form Panel ─────────────────────────────────────
                Expanded(
                  flex: 6,
                  child: Container(
                    color: cs.surface,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: s.x2l + s.xl,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildForm(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // ── Mobile View ───────────────────────────────────────────────
          return SingleChildScrollView(
            child: Column(
              children: [
                // Hero compacto móvil
                _MobileHero(),
                Padding(
                  padding: EdgeInsets.fromLTRB(s.xl, 0, s.xl, s.x2l),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildForm(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título
        Text(
          'Bienvenido de nuevo',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        SizedBox(height: s.xs),
        Text(
          'Ingresa tus credenciales para acceder al sistema.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ).animate().fadeIn(delay: 180.ms),
        SizedBox(height: s.x2l),

        // Campo usuario
        TextField(
          controller: _usernameController,
          onSubmitted: (_) => _handleSubmit(),
          decoration: const InputDecoration(
            labelText: 'Usuario',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
        SizedBox(height: s.md),

        // Campo contraseña
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          onSubmitted: (_) => _handleSubmit(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _showPassword = !_showPassword),
            ),
          ),
        ).animate().fadeIn(delay: 320.ms).slideX(begin: 0.05),
        SizedBox(height: s.xs),

        // Olvidé contraseña
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/reset_password'),
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ).animate().fadeIn(delay: 370.ms),

        // Error
        if (_errorMessage != null) ...[
          SizedBox(height: s.sm),
          _ErrorBanner(message: _errorMessage!)
              .animate()
              .shake(hz: 3, offset: const Offset(6, 0))
              .fadeIn(),
          SizedBox(height: s.sm),
        ] else
          SizedBox(height: s.lg),

        // Botón principal
        SizedBox(
          width: double.infinity,
          child: PremiumButton(
            label: 'INICIAR SESIÓN',
            icon: Icons.login_rounded,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleSubmit,
          ),
        ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.1),

        SizedBox(height: s.xl),

        // Footer
        Center(
          child: Text(
            '© 2026 NeuroApp Systems • Hospital Central',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }
}

// ── Left Branding Panel (desktop) ─────────────────────────────────────────────

class _BrandingPanel extends StatefulWidget {
  @override
  State<_BrandingPanel> createState() => _BrandingPanelState();
}

class _BrandingPanelState extends State<_BrandingPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _orb;

  @override
  void initState() {
    super.initState();
    _orb = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _orb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final glass = context.glass;

    return Container(
      decoration: BoxDecoration(gradient: glass.headerGradient),
      child: Stack(
        children: [
          // ── Orbes de fondo animados ────────────────────────────────
          AnimatedBuilder(
            animation: _orb,
            builder: (_, __) {
              final t = _orb.value;
              return Stack(
                children: [
                  // Orb 1 — top right
                  Positioned(
                    right: -80 + 40 * math.sin(t * 2 * math.pi),
                    top: -60 + 30 * math.cos(t * 2 * math.pi),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            cs.tertiary.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Orb 2 — bottom left
                  Positioned(
                    left: -60 + 20 * math.sin(t * 2 * math.pi + 2),
                    bottom: 40 + 30 * math.cos(t * 2 * math.pi + 1),
                    child: Container(
                      width: 280,
                      height: 280,
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

          // ── SVG logo como textura de fondo ────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: SvgPicture.asset(
                  'assets/svg/hospital_logo.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── Grid de puntos sutil ──────────────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(painter: _NeuralDotsPainter()),
            ),
          ),

          // ── Contenido principal ───────────────────────────────────
          Padding(
            padding: EdgeInsets.all(s.x2l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo icon con glass
                Container(
                  padding: EdgeInsets.all(s.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    size: 56,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 700.ms)
                    .scale(curve: Curves.easeOutBack),

                SizedBox(height: s.x2l),

                // App name
                Text(
                  'NeuroApp',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideX(begin: -0.1),

                SizedBox(height: s.md),

                // Divider decorativo
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 350.ms)
                    .scaleX(
                      begin: 0,
                      alignment: Alignment.centerLeft,
                    ),

                SizedBox(height: s.xl),

                // Tagline
                Text(
                  'Potenciando la\nsalud cognitiva\na través de la\ntecnología.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                        letterSpacing: -0.3,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.08),

                const Spacer(),

                // Chips de features
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeatureChip(
                      icon: Icons.shield_outlined,
                      label: 'HIPAA Compliant',
                    ),
                    _FeatureChip(
                      icon: Icons.psychology_outlined,
                      label: 'IA Cognitiva',
                    ),
                    _FeatureChip(
                      icon: Icons.analytics_outlined,
                      label: 'Análisis Avanzado',
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),

                SizedBox(height: s.xl),

                // Version
                Text(
                  '© 2026 NeuroApp Systems  •  v2.5.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Hero ────────────────────────────────────────────────────────────────

class _MobileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final glass = context.glass;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s.xl, s.x2l + 16, s.xl, s.x2l),
      decoration: BoxDecoration(gradient: glass.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(s.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                size: 40,
                color: Colors.white,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            SizedBox(height: s.lg),
            Text(
              'NeuroApp',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
            SizedBox(height: s.xs),
            Text(
              'Sistema de evaluación cognitiva',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w400,
                  ),
            ).animate().fadeIn(delay: 350.ms),
            SizedBox(height: s.xl),
          ],
        ),
      ),
    );
  }
}

// ── Feature Chip ───────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.7)),
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

// ── Error Banner ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Neural Dots Painter ────────────────────────────────────────────────────────

class _NeuralDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const spacing = 36.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

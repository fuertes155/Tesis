part of 'login_screen.dart';

class LoginScreenState extends State<LoginScreen> {
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
      final api = GetIt.I<ApiService>();
      await api.login(username, password);

      if (!mounted) return;
      final role = api.currentRole ?? 'doctor';
      _navigateBasedOnRole(role);
    } catch (e) {
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
    final r = context.radii;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          if (isWide) {
            return Row(
              children: [
                // Left Branding Panel
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.primary, cs.tertiary],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.05,
                            child: CustomPaint(painter: _PatternPainter()),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(s.x2l),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                    padding: EdgeInsets.all(s.md),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: r.radiusLg,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.psychology_outlined,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 800.ms)
                                  .scale(curve: Curves.easeOutBack),
                              SizedBox(height: s.x2l),
                              Text(
                                    'NeuroApp',
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1.5,
                                        ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideX(begin: -0.1),
                              SizedBox(height: s.lg),
                              Container(
                                    width: 80,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 400.ms)
                                  .scaleX(begin: 0),
                              SizedBox(height: s.xl),
                              Text(
                                'Potenciando la salud cognitiva a través de la tecnología.',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w300,
                                  height: 1.5,
                                ),
                              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                              const Spacer(),
                              Text(
                                '© 2026 NeuroApp Systems • v2.5.0',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white60,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right Form Panel
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: s.x2l + s.xl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _buildProfessionalForm(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cs.surface, cs.surfaceContainerHighest],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(s.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(s.lg),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          size: 72,
                          color: cs.primary,
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.bounceOut,
                      ),
                      SizedBox(height: s.lg),
                      Text(
                        'NeuroApp',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: s.x2l),
                      _buildProfessionalForm(context),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionalForm(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bienvenido de nuevo',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: s.xs),
        Text(
          'Ingresa tus credenciales para acceder.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        SizedBox(height: s.xl),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Usuario',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        SizedBox(height: s.md),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        SizedBox(height: s.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/reset_password'),
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
            ),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: s.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                  ),
                ),
              ],
            ),
          ).animate().shake(),
        ],
        SizedBox(height: s.xl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.onPrimary,
                    ),
                  )
                : const Text('Iniciar Sesión'),
          ),
        ),
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 40) {
      for (var j = 0; j < size.height; j += 40) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

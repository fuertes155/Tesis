part of 'login_screen.dart';

class LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;
  String _role = 'doctor';

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
      final username = _usernameController.text;
      final password = _passwordController.text;
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Ingresa usuario y contraseña');
      }
      final api = ApiService();
      await api.login(username, password, role: _role);

      if (!mounted) return;
      final role = api.currentRole ?? _role;
      if (role != _role) {
        setState(() {
          _role = role;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tu cuenta está asignada al rol "$role". Se iniciará con ese rol.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    final primaryColor = const Color(0xFF1A237E); // Deep Indigo/Navy
    final accentColor = const Color(0xFF3949AB);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Very light gray/blue background
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          if (isWide) {
            return Row(
              children: [
                // Left Branding Panel
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, accentColor],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.psychology_outlined,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(delay: 200.ms),
                          const SizedBox(height: 40),
                          Text(
                            'NeuroApp',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                          const SizedBox(height: 24),
                          Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ).animate().fadeIn(delay: 400.ms).scaleX(begin: 0),
                          const SizedBox(height: 32),
                          Text(
                            'Plataforma integral para evaluación y seguimiento cognitivo profesional.',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w300,
                              height: 1.4,
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                          const Spacer(),
                          Text(
                            '© 2024 NeuroApp Systems. v2.1.0',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right Form Panel
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 100),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: _buildProfessionalForm(theme, primaryColor),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: Color(0xFF1A237E),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NeuroApp',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A237E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildProfessionalForm(theme, primaryColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionalForm(ThemeData theme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Iniciar Sesión',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn().slideX(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          'Acceda a su panel de control con sus credenciales.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF64748B),
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 40),
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().shake(hz: 4, curve: Curves.easeInOut),
        const SizedBox(height: 12),
        const Text(
          'Correo Electrónico',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF334155),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'ejemplo@correo.com',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF64748B),
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          children: [
            const Text(
              'Contraseña',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF334155),
                letterSpacing: -0.2,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/reset_password'),
              child: Text(
                '¿Olvidó su contraseña?',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF64748B),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: primaryColor.withValues(alpha: 0.4),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        const SizedBox(height: 40),
        Center(
          child: Text(
            'Si no tiene acceso, solicítelo al administrador del sistema.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
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

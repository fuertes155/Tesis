part of 'mfa_screen.dart';

class _MfaScreenState extends ConsumerState<MfaScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = await ref.read(apiServiceProvider.future);
      final username = api.currentUsername;
      
      if (username == null) {
        throw Exception('No se encontró el nombre de usuario');
      }

      final success = await api.verify2FA(username, code);
      
      if (success) {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        
        final role = api.currentRole ?? 'doctor';
        
        if (role == 'doctor') {
          context.go('/home');
        } else if (role == 'gestor') {
          context.go('/users_admin');
        } else {
          context.go('/patient_welcome');
        }
      } else {
        throw Exception('Código de verificación incorrecto');
      }
    } catch (e) {
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(s.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de seguridad
                  Container(
                    padding: EdgeInsets.all(s.lg),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.security_rounded, size: 48, color: cs.primary),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                  SizedBox(height: s.xl),

                  Text(
                    'Verificación de Dos Pasos',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  SizedBox(height: s.xs),

                  Text(
                    'Ingresa el código de 6 dígitos que enviamos a tu dispositivo vinculado.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  SizedBox(height: s.x2l),

                  // Inputs del código
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 50,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary, width: 2),
                            ),
                          ),
                          onChanged: (v) => _onCodeChanged(v, index),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ).animate().fadeIn(delay: (400 + index * 50).ms).slideY(begin: 0.2);
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    SizedBox(height: s.lg),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
                          SizedBox(width: s.sm),
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

                  SizedBox(height: s.x2l),

                  PremiumButton(
                    label: 'VERIFICAR',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _verifyCode,
                  ).animate().fadeIn(delay: 800.ms),

                  SizedBox(height: s.xl),

                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      'Volver al inicio de sesión',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

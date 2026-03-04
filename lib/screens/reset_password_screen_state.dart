part of 'reset_password_screen.dart';

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final username = _usernameController.text;
      final password = _passwordController.text;
      final confirm = _confirmController.text;
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Ingresa usuario y nueva contraseña');
      }
      if (password != confirm) {
        throw Exception('Las contraseñas no coinciden');
      }
      final strong = _isStrong(password);
      if (!strong) {
        throw Exception(
          'La contraseña debe tener mínimo 8 caracteres, mayúscula, minúscula y número',
        );
      }
      if (mounted) {
        setState(() {
          _message = 'Contraseña actualizada';
        });
      }
    } catch (e) {
      setState(() {
        _message = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isStrong(String p) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(p);
    final hasLower = RegExp(r'[a-z]').hasMatch(p);
    final hasDigit = RegExp(r'\d').hasMatch(p);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
    return p.length >= 8 && hasUpper && hasLower && hasDigit && hasSpecial;
  }

  int _strengthScore(String p) {
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  String _strengthLabel(int s) {
    if (s <= 2) return 'Débil';
    if (s == 3) return 'Medio';
    if (s == 4) return 'Fuerte';
    return 'Muy Fuerte';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restablecer contraseña'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _reset(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (_) {
                    final p = _passwordController.text;
                    final score = _strengthScore(p);
                    final label = _strengthLabel(score);
                    final value = score / 5;
                    final color = score <= 2
                        ? theme.colorScheme.error
                        : score == 3
                            ? Colors.orange
                            : score == 4
                                ? Colors.green
                                : Colors.teal;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_rounded, color: color, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: theme.textTheme.labelMedium?.copyWith(color: color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Incluye mayúscula, minúscula, número y símbolo',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _reset,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('RESTABLECER'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Volver a iniciar sesión'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _message!.contains('actualizada')
                          ? Colors.green
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

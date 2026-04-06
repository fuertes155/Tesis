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
    final primaryColor = const Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.psychology_outlined, size: 40, color: primaryColor),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Bienvenido a su Evaluación',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'NeuroApp le guiará a través de una serie de pruebas diseñadas para evaluar sus funciones cognitivas de manera profesional.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildProfessionalStep(
                    icon: Icons.assignment_turned_in_outlined,
                    text: 'Lectura y aceptación de consentimiento informado.',
                  ),
                  const SizedBox(height: 16),
                  _buildProfessionalStep(
                    icon: Icons.ads_click_rounded,
                    text: 'Realización de pruebas interactivas guiadas.',
                  ),
                  const SizedBox(height: 16),
                  _buildProfessionalStep(
                    icon: Icons.timer_outlined,
                    text: 'Duración estimada: 15-20 minutos.',
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final accepted = prefs.getBool('consent_accepted') ?? false;
                        if (!context.mounted) return;
                        if (accepted) {
                          context.go('/test_selector');
                        } else {
                          context.go('/consent');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      child: const Text('COMENZAR AHORA'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('consent_accepted');
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Configuración de consentimiento restablecida'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Restablecer Consentimiento',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildProfessionalStep({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1A237E)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

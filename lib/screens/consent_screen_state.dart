part of 'consent_screen.dart';

class ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Consentimiento'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, 
                            color: theme.colorScheme.primary, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Consentimiento Informado',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 48),
                      Text(
                        'Por medio de la presente, autorizo la realización de las pruebas psicológicas y neuropsicológicas necesarias para la evaluación cognitiva.\n\n'
                        'Entiendo que:\n'
                        '1. Los datos obtenidos serán tratados con estricta confidencialidad.\n'
                        '2. Los resultados serán utilizados únicamente con fines diagnósticos y terapéuticos.\n'
                        '3. Puedo revocar este consentimiento en cualquier momento.\n'
                        '4. La evaluación puede implicar fatiga mental leve.\n\n'
                        'He leído y comprendido la información anterior y he tenido la oportunidad de hacer preguntas.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Este documento es legalmente vinculante.',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _accepted = !_accepted;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: _accepted,
                            activeColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _accepted = value ?? false;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'He leído y acepto los términos y condiciones.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _accepted
                        ? () {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Consentimiento firmado exitosamente'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : null,
                    child: const Text('CONFIRMAR Y CONTINUAR'),
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

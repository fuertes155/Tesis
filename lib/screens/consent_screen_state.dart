part of 'consent_screen.dart';

class ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final sem = context.sem;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        title: Text(
          'Consentimiento',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(spacing.lg),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: r.radiusXl,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: r.radiusXl,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(spacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(spacing.sm - 2), // ~10
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: r.radiusSm, // ~12/10
                            ),
                            child: Icon(
                              Icons.assignment_outlined,
                              color: cs.primary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: spacing.md),
                          Expanded(
                            child: Text(
                              'Consentimiento Informado',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.xl),
                      Divider(color: cs.outlineVariant),
                      SizedBox(height: spacing.xl),
                      Text(
                        'Por medio de la presente, autorizo la realización de las pruebas psicológicas y neuropsicológicas necesarias para la evaluación cognitiva.\n\n'
                        'Entiendo que:\n'
                        '1. Los datos obtenidos serán tratados con estricta confidencialidad.\n'
                        '2. Los resultados serán utilizados únicamente con fines diagnósticos y terapéuticos.\n'
                        '3. Puedo revocar este consentimiento en cualquier momento.\n'
                        '4. La evaluación puede implicar fatiga mental leve.\n\n'
                        'He leído y comprendido la información anterior y he tenido la oportunidad de hacer preguntas.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                          color: cs.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: spacing.x2l),
                      Container(
                        padding: EdgeInsets.all(spacing.md),
                        decoration: BoxDecoration(
                          color: sem.info.withValues(alpha: 0.1),
                          borderRadius: r.radiusMd,
                          border: Border.all(color: sem.info.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(spacing.sm - 2), // ~10
                              decoration: BoxDecoration(
                                color: sem.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: sem.info,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Expanded(
                              child: Text(
                                'Este documento es legalmente vinculante.',
                                style: TextStyle(
                                  color: sem.info,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.lg, spacing.lg),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _accepted = !_accepted),
                  borderRadius: r.radiusSm,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: spacing.xs),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _accepted,
                          activeColor: cs.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) =>
                              setState(() => _accepted = v ?? false),
                        ),
                        SizedBox(width: spacing.xs),
                        Expanded(
                          child: Text(
                            'He leído y acepto los términos y condiciones.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _accepted
                        ? () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('consent_accepted', true);
                            if (!context.mounted) return;
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Consentimiento firmado exitosamente',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: r.radiusSm,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
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

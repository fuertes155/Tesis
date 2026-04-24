part of 'consent_screen.dart';

class ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final sem = context.sem;
    final glass = context.glass;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.gavel_rounded, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 8),
            const Text('Consentimiento Informado'),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Documento ─────────────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.all(spacing.lg),
              decoration: BoxDecoration(
                gradient: glass.cardGradient,
                borderRadius: r.radiusXl,
                border: Border.all(color: glass.borderColor, width: 1),
                boxShadow: context.premiumShadows,
              ),
              child: ClipRRect(
                borderRadius: r.radiusXl,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(spacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Documento header
                      Container(
                        padding: EdgeInsets.all(spacing.lg),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary.withValues(alpha: 0.08),
                              cs.tertiary.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: r.radiusMd,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                color: cs.primary,
                                size: 26,
                              ),
                            ),
                            SizedBox(width: spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Consentimiento Informado',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Evaluación Neuropsicológica • NeuroApp',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: spacing.xl),

                      _ConsentSection(
                        number: '01',
                        title: 'Autorización',
                        content:
                            'Por medio de la presente, autorizo la realización de las pruebas psicológicas y neuropsicológicas necesarias para la evaluación cognitiva de acuerdo con el protocolo establecido por NeuroApp.',
                        color: cs.primary,
                      ),

                      _ConsentSection(
                        number: '02',
                        title: 'Confidencialidad',
                        content:
                            'Los datos obtenidos serán tratados con estricta confidencialidad bajo marcos legales de protección de datos. Solo el personal médico autorizado tendrá acceso a los resultados.',
                        color: cs.tertiary,
                      ),

                      _ConsentSection(
                        number: '03',
                        title: 'Propósito',
                        content:
                            'Los resultados serán utilizados únicamente con fines diagnósticos y terapéuticos, y no serán compartidos con terceros sin autorización expresa.',
                        color: const Color(0xFF8B5CF6),
                      ),

                      _ConsentSection(
                        number: '04',
                        title: 'Revocabilidad',
                        content:
                            'Puedo revocar este consentimiento en cualquier momento antes o durante la evaluación, sin que ello implique ningún tipo de consecuencia.',
                        color: const Color(0xFF10B981),
                      ),

                      _ConsentSection(
                        number: '05',
                        title: 'Efectos',
                        content:
                            'La evaluación puede implicar fatiga mental leve. He leído y comprendido la información anterior y he tenido la oportunidad de hacer preguntas.',
                        color: const Color(0xFFF59E0B),
                        isLast: true,
                      ),

                      SizedBox(height: spacing.xl),

                      // Aviso legal
                      Container(
                        padding: EdgeInsets.all(spacing.md),
                        decoration: BoxDecoration(
                          color: sem.info.withValues(alpha: 0.08),
                          borderRadius: r.radiusMd,
                          border: Border.all(
                            color: sem.info.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: sem.info, size: 18),
                            SizedBox(width: spacing.sm),
                            Expanded(
                              child: Text(
                                'Este documento es legalmente vinculante y ha sido aprobado por el comité de ética médica.',
                                style: TextStyle(
                                  color: sem.info,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  height: 1.4,
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

          // ── Footer de confirmación ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              spacing.lg,
              spacing.md,
              spacing.lg,
              spacing.lg,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(
                top: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Toggle de acceptación premium
                InkWell(
                  onTap: () => setState(() => _accepted = !_accepted),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        // Checkbox premium
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: _accepted
                                ? LinearGradient(
                                    colors: [cs.primary, cs.tertiary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _accepted ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _accepted
                                  ? cs.primary
                                  : cs.outlineVariant,
                              width: 1.5,
                            ),
                            boxShadow: _accepted
                                ? [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: _accepted
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        SizedBox(width: spacing.md),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              children: const [
                                TextSpan(text: 'He leído y acepto '),
                                TextSpan(
                                  text: 'todos los términos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(
                                    text:
                                        ' del consentimiento informado.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: spacing.md),

                // Botón confirmar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: FilledButton.icon(
                      onPressed: (_accepted && !_isProcessing)
                          ? () async {
                              setState(() => _isProcessing = true);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('consent_accepted', true);
                              if (!context.mounted) return;
                              setState(() => _isProcessing = false);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Consentimiento firmado exitosamente'),
                                ),
                              );
                            }
                          : null,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_rounded),
                      label: Text(
                        _isProcessing
                            ? 'Procesando...'
                            : 'CONFIRMAR Y CONTINUAR',
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
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

// ── Consent Section ───────────────────────────────────────────────────────────

class _ConsentSection extends StatelessWidget {
  const _ConsentSection({
    required this.number,
    required this.title,
    required this.content,
    required this.color,
    this.isLast = false,
  });

  final String number;
  final String title;
  final String content;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número y línea
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: spacing.md),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
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

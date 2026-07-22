part of 'create_patient_screen.dart';

class CreatePatientScreenState extends ConsumerState<CreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _docIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _diagnosisController = TextEditingController(text: 'Pendiente');
  bool _isLoading = false;
  bool _hasConsent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _docIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _createPatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debe aceptar el consentimiento informado.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final api = await ref.read(apiServiceProvider.future);
      int age = 0;
      final text = _birthDateController.text.trim();
      if (text.isNotEmpty) {
        DateTime? date;
        final parts = text.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            date = DateTime(y, m, d);
          }
        }
        date ??= DateTime.tryParse(text);
        if (date != null) {
          final now = DateTime.now();
          int years = now.year - date.year;
          final hasHadBirthday = (now.month > date.month) ||
              (now.month == date.month && now.day >= date.day);
          if (!hasHadBirthday) years -= 1;
          age = years.clamp(0, 120);
        }
      }

      await api.createPatient({
        'name': _nameController.text,
        'age': age,
        'birth_date': _birthDateController.text,
        'document_id': _docIdController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'diagnosis': 'Pendiente',
        'has_consent': _hasConsent,
      });
      api.pushNotice('patient_created');

      if (mounted) {
        HapticFeedback.heavyImpact();
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.check_circle_rounded, size: 64, color: context.sem.success)
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack)
                .shake(delay: 200.ms),
            title: const Text('¡Éxito!'),
            content: const Text(
              'El expediente del paciente ha sido creado y guardado correctamente en el sistema.',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        );
        if (mounted) context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear paciente: $e'),
            backgroundColor: context.sem.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final glass = context.glass;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Nuevo Paciente'),
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero banner ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  spacing.lg, spacing.xl, spacing.lg, spacing.x2l + spacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.08),
                    cs.tertiary.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_shared_outlined,
                            size: 12, color: cs.primary),
                        const SizedBox(width: 5),
                        Text(
                          'REGISTRO CLÍNICO',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideX(begin: -0.15),
                  SizedBox(height: spacing.sm),
                  Text(
                    'Información del\nPaciente',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.08),
                  SizedBox(height: spacing.xs),
                  Text(
                    'Complete los datos para crear el expediente digital.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),

            // ── Formulario flotante ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  padding: EdgeInsets.all(spacing.xl),
                  decoration: BoxDecoration(
                    gradient: glass.cardGradient,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: glass.borderColor, width: 1),
                    boxShadow: context.premiumShadows,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Sección Datos Personales ────────────────────
                        _SectionHeader(
                          icon: Icons.person_outline_rounded,
                          label: 'Datos Personales',
                          color: cs.primary,
                        ),
                        SizedBox(height: spacing.lg),

                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Completo',
                            hintText: 'Ej. Juan Alberto Pérez García',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requerido' : null,
                        ).animate().fadeIn(delay: 250.ms),
                        SizedBox(height: spacing.md),

                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Nacimiento',
                            hintText: 'Seleccionar fecha',
                            prefixIcon:
                                Icon(Icons.calendar_today_outlined),
                          ),
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now.subtract(
                                const Duration(days: 365 * 30),
                              ),
                              firstDate: DateTime(1900),
                              lastDate: now,
                            );
                            if (picked != null) {
                              _birthDateController.text =
                                  '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                            }
                          },
                        ).animate().fadeIn(delay: 300.ms),

                        SizedBox(height: spacing.xl),

                        // ── Sección Identificación ──────────────────────
                        _SectionHeader(
                          icon: Icons.badge_outlined,
                          label: 'Identificación',
                          color: cs.tertiary,
                        ),
                        SizedBox(height: spacing.lg),

                        TextFormField(
                          controller: _docIdController,
                          decoration: const InputDecoration(
                            labelText: 'Cédula / Documento de Identidad',
                            hintText: 'Número de documento o cédula',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                        ).animate().fadeIn(delay: 350.ms),
                        SizedBox(height: spacing.md),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            hintText: '+1 234 567 890',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        SizedBox(height: spacing.md),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico (Opcional)',
                            hintText: 'ejemplo@correo.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ).animate().fadeIn(delay: 420.ms),

                        SizedBox(height: spacing.xl),

                        // ── Consentimiento Informado ────────────────────
                        _SectionHeader(
                          icon: Icons.verified_user_outlined,
                          label: 'Consentimiento',
                          color: cs.secondary,
                        ),
                        SizedBox(height: spacing.lg),

                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: CheckboxListTile(
                            value: _hasConsent,
                            onChanged: (val) {
                              setState(() => _hasConsent = val ?? false);
                            },
                            title: const Text('Consentimiento Informado'),
                            subtitle: const Text('El paciente o su tutor legal ha firmado el consentimiento para el tratamiento de datos y terapias.'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ).animate().fadeIn(delay: 440.ms),

                        SizedBox(height: spacing.x2l),

                        // ── Botón de submit ─────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton.icon(
                            onPressed:
                                _isLoading ? null : _createPatient,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_add_rounded,
                                    size: 20,
                                  ),
                            label: Text(
                              _isLoading
                                  ? 'Creando expediente...'
                                  : 'Crear Expediente',
                            ),
                          ),
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: spacing.x2l),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        SizedBox(width: spacing.sm),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: color.withValues(alpha: 0.80),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

part of 'create_patient_screen.dart';

class CreatePatientScreenState extends State<CreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _docIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _diagnosisController = TextEditingController(text: 'Pendiente');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _docIdController.dispose();
    _phoneController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _createPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final api = GetIt.I<ApiService>();
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
          final hasHadBirthday =
              (now.month > date.month) ||
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
        'diagnosis': 'Pendiente',
      });
      api.pushNotice('patient_created');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente creado exitosamente'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear paciente: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
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
    final r = context.radii;
    final spacing = context.spacing;
    final sem = context.sem;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Nuevo Paciente'),
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(spacing.lg, spacing.xl, spacing.lg, spacing.x2l + spacing.md), // ~24, 32, 24, 48
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.surfaceContainerLowest, cs.surface],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REGISTRO CLÍNICO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2),
                  SizedBox(height: spacing.sm),
                  Text(
                    'Información del Paciente',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  padding: EdgeInsets.all(spacing.xl),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: r.radiusXl, // ~28
                    border: Border.all(color: cs.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.05),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          Icons.person_outline,
                          'Datos Personales',
                        ),
                        SizedBox(height: spacing.lg),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Completo',
                            hintText: 'Ej. Juan Alberto Pérez',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        SizedBox(height: spacing.md),
                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Nacimiento',
                            hintText: 'Seleccionar fecha',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
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
                              builder: (context, child) {
                                return Theme(
                                  data: theme.copyWith(
                                    colorScheme: cs.copyWith(
                                      primary: cs.primary,
                                      onPrimary: cs.onPrimary,
                                      surface: cs.surfaceContainerLowest,
                                      onSurface: cs.onSurface,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              _birthDateController.text =
                                  '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                            }
                          },
                        ),
                        SizedBox(height: spacing.xl),
                        _buildSectionHeader(
                          context,
                          Icons.contact_mail,
                          'Identificación',
                        ),
                        SizedBox(height: spacing.lg),
                        TextFormField(
                          controller: _docIdController,
                          decoration: const InputDecoration(
                            labelText: 'Documento de Identidad',
                            hintText: 'Número de documento',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        SizedBox(height: spacing.md),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            hintText: '+1 234 567 890',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        SizedBox(height: spacing.x2l),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _createPatient,
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : const Text('Crear Expediente'),
                          ),
                        ),
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

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    final cs = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        SizedBox(width: spacing.sm),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

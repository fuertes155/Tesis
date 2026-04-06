part of 'create_patient_screen.dart';

class CreatePatientScreenState extends State<CreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _docIdController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _docIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final api = ApiService();
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
        'diagnosis': 'Pendiente',
      });

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
    final primaryColor = const Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nuevo Paciente',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'REGISTRO CLÍNICO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete la información del paciente para crear su expediente digital.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfessionalLabel('Nombre Completo'),
                    _buildProfessionalField(
                      controller: _nameController,
                      hint: 'Ej. Juan Alberto Pérez',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildProfessionalLabel('Fecha de Nacimiento'),
                    _buildProfessionalField(
                      controller: _birthDateController,
                      hint: 'DD/MM/AAAA',
                      icon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: () async {
                        final now = DateTime.now();
                        final initial = now.subtract(const Duration(days: 365 * 30));
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(1900),
                          lastDate: now,
                        );
                        if (picked != null) {
                          final dd = picked.day.toString().padLeft(2, '0');
                          final mm = picked.month.toString().padLeft(2, '0');
                          final yyyy = picked.year.toString();
                          _birthDateController.text = '$dd/$mm/$yyyy';
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildProfessionalLabel('Documento de Identidad'),
                    _buildProfessionalField(
                      controller: _docIdController,
                      hint: 'Número de documento',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 24),
                    _buildProfessionalLabel('Teléfono de Contacto'),
                    _buildProfessionalField(
                      controller: _phoneController,
                      hint: '+1 234 567 890',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createPatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('CREAR EXPEDIENTE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildProfessionalField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

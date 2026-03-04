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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Crear Paciente'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos Personales',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingrese la información del nuevo paciente',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _birthDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        prefixIcon: Icon(Icons.cake_outlined),
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                        hintText: 'DD/MM/AAAA',
                      ),
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
                    TextFormField(
                      controller: _docIdController,
                      decoration: const InputDecoration(
                        labelText: 'Documento de Identidad',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono de Contacto',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createPatient,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('GUARDAR PACIENTE'),
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
}

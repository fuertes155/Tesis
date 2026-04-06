part of 'users_admin_screen.dart';

class UsersAdminScreenState extends State<UsersAdminScreen> {
  List<dynamic> _users = [];
  List<dynamic> _patients = [];
  bool _isLoading = true;
  String _patientQuery = '';
  String _doctorQuery = '';
  bool _showOnlyAvailableDoctors = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([api.getUsers(), api.getPatients()]);
      setState(() {
        _users = results[0];
        _patients = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAvailability(int userId, bool currentStatus) async {
    try {
      await ApiService().updateUserAvailability(userId, !currentStatus);
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _assignDoctor(int patientId) async {
    final doctors = _users
        .where((u) => u['role'] == 'doctor' && (u['is_available'] ?? true))
        .toList();
    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay médicos disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final doctorId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Asignar Médico'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: doctors
              .map(
                (d) => ListTile(
                  title: Text(d['username']),
                  onTap: () => Navigator.pop(ctx, d['id']),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (doctorId != null) {
      try {
        await ApiService().assignDoctorToPatient(patientId, doctorId);
        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showCreateUserDialog() async {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    String selectedRole = 'doctor';
    final api = ApiService();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Crear Nuevo Usuario',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rol del Usuario',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      onChanged: (v) => setDialogState(() => selectedRole = v!),
                      items: const [
                        DropdownMenuItem(
                          value: 'gestor',
                          child: Text('Administrador (Gestor)'),
                        ),
                        DropdownMenuItem(
                          value: 'doctor',
                          child: Text('Doctor'),
                        ),
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('Paciente (User)'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedRole == 'doctor') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        '¿Disponible inicialmente?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: true, // Default to available
                        onChanged: (val) {
                          // This is a simplified UI for the dialog
                          // The backend default is already 1 (True)
                        },
                        activeThumbColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const Text(
                    'Los doctores se crean como "DISPONIBLES" por defecto.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () async {
                if (emailController.text.isEmpty ||
                    passController.text.isEmpty) {
                  return;
                }
                try {
                  await api.adminCreateUser(
                    username: emailController.text,
                    password: passController.text,
                    role: selectedRole,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx, true);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('CREAR USUARIO'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doctorsAll = _users.where((u) => u['role'] == 'doctor').toList();
    final doctors = _showOnlyAvailableDoctors
        ? doctorsAll.where((d) => (d['is_available'] ?? true) == true).toList()
        : doctorsAll;

    final patients = _patients;
    final doctorNamesById = <int, String>{};
    for (final d in doctorsAll) {
      final id = d['id'];
      if (id is int) {
        doctorNamesById[id] = d['username']?.toString() ?? 'Doctor';
      } else if (id is String) {
        final parsed = int.tryParse(id);
        if (parsed != null) {
          doctorNamesById[parsed] = d['username']?.toString() ?? 'Doctor';
        }
      }
    }

    final patientsPerDoctor = <int, int>{};
    for (final p in patients) {
      final did = p['doctor_id'];
      final int? doctorId = did is int
          ? did
          : (did is String ? int.tryParse(did) : null);
      if (doctorId != null) {
        patientsPerDoctor[doctorId] = (patientsPerDoctor[doctorId] ?? 0) + 1;
      }
    }

    final filteredDoctors = doctors.where((d) {
      final q = _doctorQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      final username = (d['username'] ?? '').toString().toLowerCase();
      return username.contains(q);
    }).toList();

    final filteredPatients = patients.where((p) {
      final q = _patientQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      final name = (p['name'] ?? '').toString().toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      final diag = (p['diagnosis'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || diag.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const HomeHeader(),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _fetchData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            onPressed: () async {
              await ApiService().logout();
              if (!context.mounted) return;
              context.go('/');
            },
            tooltip: 'Cerrar Sesión',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final horizontal = w < 720 ? 16.0 : 60.0;
                final vertical = w < 720 ? 24.0 : 48.0;

                return SingleChildScrollView(
                  child: PageContainer(
                    maxWidth: 1400,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontal,
                      vertical: vertical,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panel de Administrador',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E293B),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestiona usuarios, médicos y pacientes desde un solo lugar.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 28),
                        LayoutBuilder(
                          builder: (context, c) {
                            final isNarrow = c.maxWidth < 980;
                            final cardWidth = isNarrow
                                ? double.infinity
                                : (c.maxWidth - 16 * 3) / 4;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Pacientes',
                                    value: '${_patients.length}',
                                    icon: Icons.people_alt_outlined,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Doctores',
                                    value: '${doctorsAll.length}',
                                    icon: Icons.medical_services_outlined,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: StatCard(
                                    title: 'Disponibles',
                                    value:
                                        '${doctorsAll.where((d) => (d['is_available'] ?? true) == true).length}',
                                    icon: Icons.check_circle_outline,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  height: 84,
                                  child: FilledButton.icon(
                                    onPressed: _showCreateUserDialog,
                                    icon: const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 20,
                                    ),
                                    label: const Text('Nuevo Usuario'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        _buildSectionHeader(
                          'Médicos',
                          Icons.medical_services_outlined,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final stacked = c.maxWidth < 520;
                              final field = TextField(
                                decoration: InputDecoration(
                                  hintText: 'Buscar médico...',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (v) =>
                                    setState(() => _doctorQuery = v),
                              );
                              final chip = FilterChip(
                                label: const Text('Solo disponibles'),
                                selected: _showOnlyAvailableDoctors,
                                onSelected: (v) => setState(
                                  () => _showOnlyAvailableDoctors = v,
                                ),
                              );
                              if (stacked) {
                                return Column(
                                  children: [
                                    field,
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: chip,
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: field),
                                  const SizedBox(width: 16),
                                  chip,
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfessionalTable(
                          filteredDoctors,
                          tableType: 'doctor',
                          doctorNamesById: doctorNamesById,
                          patientsPerDoctor: patientsPerDoctor,
                        ),

                        const SizedBox(height: 56),

                        _buildSectionHeader(
                          'Pacientes',
                          Icons.people_alt_outlined,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar paciente (nombre, teléfono, diagnóstico)...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                              ),
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) => setState(() => _patientQuery = v),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfessionalTable(
                          filteredPatients,
                          tableType: 'patient',
                          doctorNamesById: doctorNamesById,
                          patientsPerDoctor: patientsPerDoctor,
                        ),

                        const SizedBox(height: 56),

                        _buildSectionHeader(
                          'Administradores del Sistema',
                          Icons.admin_panel_settings_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildProfessionalTable(
                          _users.where((u) => u['role'] == 'gestor').toList(),
                          tableType: 'admin',
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 26, color: const Color(0xFF1A237E)),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF334155),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalTable(
    List<dynamic> items, {
    required String tableType,
    Map<int, String>? doctorNamesById,
    Map<int, int>? patientsPerDoctor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available =
                (constraints.maxWidth.isFinite && constraints.maxWidth > 0)
                ? constraints.maxWidth
                : 1100.0;
            final tableWidth = available < 1100.0 ? 1100.0 : available;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _headerCell('USUARIO')),
                          Expanded(flex: 3, child: _headerCell('CONTACTO')),
                          SizedBox(width: 160, child: _headerCell('REGISTRO')),
                          SizedBox(width: 140, child: _headerCell('ESTADO')),
                          SizedBox(width: 100, child: _headerCell('ACCIONES')),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    if (items.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: [
                          for (
                            int index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            _buildProfessionalRow(
                              items[index],
                              tableType,
                              doctorNamesById: doctorNamesById,
                              patientsPerDoctor: patientsPerDoctor,
                            ),
                            if (index != items.length - 1)
                              const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildProfessionalRow(
    dynamic item,
    String tableType, {
    Map<int, String>? doctorNamesById,
    Map<int, int>? patientsPerDoctor,
  }) {
    final bool isStaff = tableType == 'admin' || tableType == 'doctor';
    final name = isStaff
        ? (item['username'] ?? 'Sin nombre')
        : (item['name'] ?? 'Sin nombre');
    final id = item['id'].toString();
    final email = isStaff ? item['username'] : (item['phone'] ?? 'N/A');
    final dateStr = item['registration_date'] != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.parse(item['registration_date']))
        : '---';

    String statusText;
    Color statusColor;
    bool isActive = true;

    if (tableType == 'admin') {
      isActive = item['is_active'] ?? true;
      statusText = isActive ? 'ACTIVO' : 'INACTIVO';
      statusColor = isActive
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444);
    } else if (tableType == 'doctor') {
      isActive = item['is_available'] ?? true;
      statusText = isActive ? 'DISPONIBLE' : 'OCUPADO';
      statusColor = isActive
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444);
    } else {
      final isAssigned = item['doctor_id'] != null;
      statusText = isAssigned ? 'ASIGNADO' : 'PENDIENTE';
      statusColor = isAssigned
          ? const Color(0xFF3B82F6)
          : const Color(0xFFF59E0B);
    }

    // Initials for avatar (first two words)
    String initials = '';
    final parts = name.toString().split(' ');
    if (parts.length >= 2) {
      initials = (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts[0].isNotEmpty) {
      initials = parts[0]
          .substring(0, parts[0].length > 1 ? 2 : 1)
          .toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          // USUARIO
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $id ${isStaff ? "(${item['role'].toString().toUpperCase()})" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // CONTACTO
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  isStaff ? Icons.email_outlined : Icons.phone_android_outlined,
                  size: 18,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tableType == 'patient') ...[
                        const SizedBox(height: 4),
                        Builder(
                          builder: (_) {
                            final did = item['doctor_id'];
                            final int? doctorId = did is int
                                ? did
                                : (did is String ? int.tryParse(did) : null);
                            final doctorName = doctorId != null
                                ? (doctorNamesById?[doctorId] ?? 'Doctor')
                                : null;
                            return Text(
                              doctorName == null
                                  ? 'Sin asignar'
                                  : 'Asignado a: $doctorName',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: doctorName == null
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF3B82F6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ] else if (tableType == 'doctor') ...[
                        const SizedBox(height: 4),
                        Builder(
                          builder: (_) {
                            final idVal = item['id'];
                            final int? doctorId = idVal is int
                                ? idVal
                                : (idVal is String
                                      ? int.tryParse(idVal)
                                      : null);
                            final count = doctorId != null
                                ? (patientsPerDoctor?[doctorId] ?? 0)
                                : 0;
                            return Text(
                              'Pacientes asignados: $count',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // REGISTRO
          SizedBox(
            width: 160,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          // ESTADO
          SizedBox(
            width: 140,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          // ACTIONS
          SizedBox(
            width: 100,
            child: Row(
              children: [
                if (tableType == 'patient')
                  IconButton(
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 22,
                      color: Color(0xFF3B82F6),
                    ),
                    onPressed: () => _assignDoctor(item['id']),
                    tooltip: 'Asignar Médico',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else if (tableType == 'doctor')
                  IconButton(
                    icon: Icon(
                      isActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      size: 32,
                      color: isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFCBD5E1),
                    ),
                    onPressed: () => _toggleAvailability(item['id'], isActive),
                    tooltip: 'Cambiar Disponibilidad',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.edit_square,
                  size: 20,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 20),
            Text(
              'No se encontraron registros',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

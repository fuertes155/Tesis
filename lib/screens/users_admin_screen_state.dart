part of 'users_admin_screen.dart';

class UsersAdminScreenState extends State<UsersAdminScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _patients = [];
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
      final api = GetIt.I<ApiService>();
      final results = await Future.wait([api.getUsers(), api.getPatients()]);
      final users = results[0] as List<User>;
      final patients = results[1] as List<Patient>;
      setState(() {
        _users = users.map(_userToMap).toList();
        _patients = patients.map(_patientToMap).toList();
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
      final api = GetIt.I<ApiService>();
      await api.updateUserAvailability(userId, !currentStatus);
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
        final api = GetIt.I<ApiService>();
        await api.assignDoctorToPatient(patientId, doctorId);
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
    final api = GetIt.I<ApiService>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          final r = context.radii;
          return AlertDialog(
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
                      border: OutlineInputBorder(borderRadius: r.radiusSm),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(borderRadius: r.radiusSm),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rol del Usuario',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: r.radiusSm,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        onChanged: (v) =>
                            setDialogState(() => selectedRole = v!),
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
                        Text(
                          '¿Disponible inicialmente?',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: true, // Default to available
                          onChanged: (val) {
                            // This is a simplified UI for the dialog
                            // The backend default is already 1 (True)
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Los doctores se crean como "DISPONIBLES" por defecto.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
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
                child: const Text('Cancelar'),
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
                          backgroundColor: cs.error,
                        ),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: r.radiusSm),
                ),
                child: const Text('Crear usuario'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final r = context.radii;
    final sem = context.sem;
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const HomeHeader(),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final api = GetIt.I<ApiService>();
              await api.logout();
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
                final horizontal = w < 720 ? s.md : s.x2l + s.md;
                final vertical = w < 720 ? s.lg : s.x2l;

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontal,
                        vertical: vertical,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: PageContainer(
                          maxWidth: 1400,
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panel de Administrador',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              SizedBox(height: s.xs),
                              Text(
                                'Gestiona usuarios, médicos y pacientes desde un solo lugar.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: s.lg + s.xs),
                              LayoutBuilder(
                                builder: (context, c) {
                                  final isNarrow = c.maxWidth < 980;
                                  final cardWidth = isNarrow
                                      ? double.infinity
                                      : (c.maxWidth - 16 * 3) / 4;
                                  return Wrap(
                                    spacing: s.md,
                                    runSpacing: s.md,
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
                                          color: sem.success,
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
                                            backgroundColor: cs.primary,
                                            foregroundColor: cs.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: r.radiusLg,
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
                              SizedBox(height: s.xl),

                              _buildSectionHeader(
                                'Médicos',
                                Icons.medical_services_outlined,
                              ),
                              SizedBox(height: s.md + s.xs),
                              Container(
                                padding: EdgeInsets.all(s.md),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: r.radiusMd,
                                  border: Border.all(color: cs.outlineVariant),
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
                                        fillColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                          SizedBox(height: s.sm),
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
                                        SizedBox(width: s.md),
                                        chip,
                                      ],
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: s.md),
                              _buildProfessionalTable(
                                filteredDoctors,
                                tableType: 'doctor',
                                doctorNamesById: doctorNamesById,
                                patientsPerDoctor: patientsPerDoctor,
                              ),

                              SizedBox(height: s.x2l + s.sm),

                              _buildSectionHeader(
                                'Pacientes',
                                Icons.people_alt_outlined,
                              ),
                              SizedBox(height: s.md + s.xs),
                              Container(
                                padding: EdgeInsets.all(s.md),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: r.radiusMd,
                                  border: Border.all(color: cs.outlineVariant),
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
                                    fillColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      setState(() => _patientQuery = v),
                                ),
                              ),
                              SizedBox(height: s.md),
                              _buildProfessionalTable(
                                filteredPatients,
                                tableType: 'patient',
                                doctorNamesById: doctorNamesById,
                                patientsPerDoctor: patientsPerDoctor,
                              ),

                              SizedBox(height: s.x2l + s.sm),

                              _buildSectionHeader(
                                'Administradores del Sistema',
                                Icons.admin_panel_settings_outlined,
                              ),
                              SizedBox(height: s.md + s.xs),
                              _buildProfessionalTable(
                                _users
                                    .where((u) => u['role'] == 'gestor')
                                    .toList(),
                                tableType: 'admin',
                              ),

                              SizedBox(height: s.x2l + s.lg),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    return Container(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 26, color: cs.primary),
          SizedBox(width: s.sm),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: r.radiusSm,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r.radiusSm,
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
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _headerCell('USUARIO')),
                          Expanded(flex: 3, child: _headerCell('CONTACTO')),
                          SizedBox(width: 160, child: _headerCell('REGISTRO')),
                          SizedBox(width: 140, child: _headerCell('ESTADO')),
                          SizedBox(width: 120, child: _headerCell('ACCIONES')),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: cs.outlineVariant),
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
                              Divider(height: 1, color: cs.outlineVariant),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w900,
        color: cs.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sem = context.sem;
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
      statusColor = isActive ? sem.success : sem.danger;
    } else if (tableType == 'doctor') {
      isActive = item['is_available'] ?? true;
      statusText = isActive ? 'DISPONIBLE' : 'OCUPADO';
      statusColor = isActive ? sem.success : sem.danger;
    } else {
      final isAssigned = item['doctor_id'] != null;
      statusText = isAssigned ? 'ASIGNADO' : 'PENDIENTE';
      statusColor = isAssigned ? sem.info : sem.warning;
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
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $id ${isStaff ? "(${item['role'].toString().toUpperCase()})" : ""}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
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
                  color: sem.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
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
                                    ? sem.warning
                                    : sem.info,
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
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
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
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  dateStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
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
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tableType == 'patient')
                  IconButton(
                    icon: Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 22,
                      color: sem.info,
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
                      color: isActive ? sem.success : cs.outlineVariant,
                    ),
                    onPressed: () => _toggleAvailability(item['id'], isActive),
                    tooltip: 'Cambiar Disponibilidad',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.edit_square,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () => _editItem(item, tableType),
                  tooltip: 'Editar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editItem(dynamic item, String tableType) async {
    final api = GetIt.I<ApiService>();

    if (tableType == 'patient') {
      final nameCtrl = TextEditingController(
        text: (item['name'] ?? '').toString(),
      );
      final ageCtrl = TextEditingController(
        text: (item['age'] ?? '').toString(),
      );
      final phoneCtrl = TextEditingController(
        text: (item['phone'] ?? '').toString(),
      );
      final diagnosisCtrl = TextEditingController(
        text: (item['diagnosis'] ?? '').toString(),
      );

      final res = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Editar paciente'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ageCtrl,
                    decoration: const InputDecoration(labelText: 'Edad'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: diagnosisCtrl,
                    decoration: const InputDecoration(labelText: 'Diagnóstico'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );

      if (res != true) return;

      final name = nameCtrl.text.trim();
      final age = int.tryParse(ageCtrl.text.trim());
      if (name.isEmpty || age == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre y edad son obligatorios')),
        );
        return;
      }

      await api.updatePatient(int.parse(item['id'].toString()), {
        'name': name,
        'age': age,
        'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        'diagnosis': diagnosisCtrl.text.trim().isEmpty
            ? null
            : diagnosisCtrl.text.trim(),
      });
      await _fetchData();
      return;
    }

    final usernameCtrl = TextEditingController(
      text: (item['username'] ?? '').toString(),
    );
    bool isActive = (item['is_active'] ?? true) == true;
    bool isAvailable = (item['is_available'] ?? true) == true;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                tableType == 'doctor'
                    ? 'Editar médico'
                    : 'Editar administrador',
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo/Usuario',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (tableType == 'admin')
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isActive,
                        onChanged: (v) => setLocal(() => isActive = v),
                        title: const Text('Activo'),
                      ),
                    if (tableType == 'doctor')
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isAvailable,
                        onChanged: (v) => setLocal(() => isAvailable = v),
                        title: const Text('Disponible'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (res != true) return;

    final username = usernameCtrl.text.trim();
    if (username.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El usuario/correo es obligatorio')),
      );
      return;
    }

    final userId = int.parse(item['id'].toString());
    final payload = <String, dynamic>{'username': username};
    if (tableType == 'admin') payload['is_active'] = isActive;
    if (tableType == 'doctor') payload['is_available'] = isAvailable;

    await api.updateUser(userId, payload);
    await _fetchData();
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

  Map<String, dynamic> _userToMap(User u) {
    return {
      'id': u.id,
      'username': u.username,
      'role': u.role,
      'is_active': u.isActive,
      'is_available': u.isAvailable,
      'registration_date': u.registrationDate ?? u.createdAt,
    };
  }

  Map<String, dynamic> _patientToMap(Patient p) {
    return {
      'id': p.id,
      'name': p.name,
      'age': p.age,
      'phone': p.phone,
      'diagnosis': p.diagnosis,
      'doctor_id': p.doctorId,
      'created_at': p.createdAt,
    };
  }
}

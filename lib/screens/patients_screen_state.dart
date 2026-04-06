part of 'patients_screen.dart';

class PatientsScreenState extends State<PatientsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _patients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _noticeBanner;

  @override
  void initState() {
    super.initState();
    final api = ApiService();
    if (api.currentRole == 'user') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/test_selector');
      });
    } else {
      _fetchPatients();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final n = ApiService().takeNotice();
        if (n == 'no_perms_history') {
          setState(() {
            _noticeBanner =
                'Acceso a Resultados restringido a Doctores. Puedes gestionar pacientes desde aquí.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes permisos para ver el historial'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  Future<void> _fetchPatients() async {
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final results = await _api.getPatients();
      setState(() {
        _patients = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF1A237E);
    final role = ApiService().currentRole;
    final canDelete = role == 'gestor';
    final filteredPatients = _patients
        .where(
          (patient) => (patient['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'Gestión de Pacientes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              if (role == 'gestor')
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton.filled(
                    onPressed: () async {
                      final result = await context.push('/create_patient');
                      if (!mounted) return;
                      if (result == true) await _fetchPatients();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Nuevo Paciente',
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (_noticeBanner != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _noticeBanner!,
                              style: const TextStyle(
                                color: Color(0xFF075985),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF0284C7),
                            ),
                            onPressed: () =>
                                setState(() => _noticeBanner = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextFormField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredPatients.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron pacientes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final patient = filteredPatients[index];
                  final name = patient['name'] ?? 'Desconocido';
                  final id = patient['id']?.toString() ?? '?';
                  final age = patient['age']?.toString() ?? '?';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          'ID: $id • $age años',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                              onPressed: () async {
                                final result = await context.push(
                                  '/patient_detail',
                                  extra: {'name': name, 'id': patient['id']},
                                );
                                if (result == true) {
                                  await _fetchPatients();
                                }
                              },
                            ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444),
                                ),
                                onPressed: () async {
                                  int? count;
                                  final intId = int.tryParse(id);
                                  if (intId != null) {
                                    try {
                                      count = await _api
                                          .getSessionsCountForPatient(intId);
                                    } catch (_) {
                                      count = null;
                                    }
                                  }
                                  if (!context.mounted) return;
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Eliminar paciente'),
                                      content: Text(
                                        count == null
                                            ? '¿Seguro que deseas eliminar a "$name"? Esta acción es permanente.'
                                            : 'Vas a eliminar a "$name" y $count sesión(es) asociada(s). Esta acción es permanente.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFEF4444,
                                            ),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (confirmed != true) return;
                                  try {
                                    if (intId != null) {
                                      await _api.deletePatient(intId);
                                    }
                                    if (mounted) {
                                      setState(() {
                                        _patients.removeWhere(
                                          (p) => p['id']?.toString() == id,
                                        );
                                      });
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Paciente eliminado correctamente',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'No se pudo eliminar: $e',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: const Color(
                                            0xFFEF4444,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                }, childCount: filteredPatients.length),
              ),
            ),
        ],
      ),
    );
  }
}

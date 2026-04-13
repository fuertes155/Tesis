part of 'patients_screen.dart';

class PatientsScreenState extends State<PatientsScreen> {
  final ApiService _api = GetIt.I<ApiService>();
  List<dynamic> _patients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _noticeBanner;

  @override
  void initState() {
    super.initState();
    final api = GetIt.I<ApiService>();
    if (api.currentRole == 'user') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/test_selector');
      });
    } else {
      _fetchPatients();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final n = api.takeNotice();
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
    setState(() => _isLoading = true);
    try {
      final api = GetIt.I<ApiService>();
      final list = await api.getPatients();
      setState(() {
        _patients = list;
        _isLoading = false;
      });

      if (mounted) {
        final n = api.takeNotice();
        if (n == 'patient_created') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente registrado con éxito')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final sem = context.sem;
    final role = GetIt.I<ApiService>().currentRole;
    final canDelete = role == 'gestor';
    final filteredPatients = _patients
        .where(
          (patient) => (patient['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: cs.surfaceContainerLowest,
            surfaceTintColor: cs.surfaceContainerLowest,
            elevation: 0,
            centerTitle: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: spacing.lg, bottom: spacing.md),
              title: Text(
                'Gestión de Pacientes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              if (role == 'gestor')
                Padding(
                  padding: EdgeInsets.only(right: spacing.md),
                  child: IconButton.filled(
                    onPressed: () async {
                      final result = await context.push('/create_patient');
                      if (!mounted) return;
                      if (result == true) await _fetchPatients();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
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
                    padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
                    child: Container(
                      padding: EdgeInsets.all(spacing.md),
                      decoration: BoxDecoration(
                        color: sem.info.withValues(alpha: 0.1),
                        borderRadius: r.radiusMd,
                        border: Border.all(color: sem.info.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: sem.info,
                          ),
                          SizedBox(width: spacing.md),
                          Expanded(
                            child: Text(
                              _noticeBanner!,
                              style: TextStyle(
                                color: sem.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: sem.info,
                            ),
                            onPressed: () =>
                                setState(() => _noticeBanner = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: TextFormField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLowest,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: r.radiusSm,
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: r.radiusSm,
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: spacing.md),
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
                      color: cs.outline,
                    ),
                    SizedBox(height: spacing.md),
                    Text(
                      'No se encontraron pacientes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final patient = filteredPatients[index];
                  final name = patient['name'] ?? 'Desconocido';
                  final id = patient['id']?.toString() ?? '?';
                  final age = patient['age']?.toString() ?? '?';
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.sm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: r.radiusMd,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: spacing.lg,
                          vertical: spacing.xs,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: cs.primary.withValues(alpha: 0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'ID: $id • $age años',
                          style: TextStyle(color: cs.onSurfaceVariant),
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
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: sem.danger,
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

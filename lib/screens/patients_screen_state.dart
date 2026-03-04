part of 'patients_screen.dart';

class PatientsScreenState extends State<PatientsScreen> {
  List<dynamic> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final patients = await api.getPatients();
      setState(() {
        _patients = patients;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _patients = [
          {'name': 'Juan Pérez', 'id': 1, 'age': 45},
          {'name': 'María García', 'id': 2, 'age': 62},
        ];
      });
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
    final filteredPatients = _patients
        .where(
          (patient) => (patient['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('Pacientes'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/create_patient');
          if (!mounted) return;
          if (result == true) {
            await _fetchPatients();
          }
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo Paciente'),
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar paciente...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchPatients,
                    child: filteredPatients.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 64,
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No se encontraron pacientes',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            itemCount: filteredPatients.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final patient = filteredPatients[index];
                              final name = patient['name'] ?? 'Desconocido';
                              final id = patient['id']?.toString() ?? '?';
                              final age = patient['age']?.toString() ?? '?';
                              return Card(
                                elevation: 0,
                                color: theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final result = await context.push(
                                      '/patient_detail',
                                      extra: {
                                        'name': name,
                                        'id': patient['id'],
                                      },
                                    );
                                    if (result == true) {
                                      await _fetchPatients();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: theme
                                              .colorScheme
                                              .primaryContainer,
                                          child: Text(
                                            name.isNotEmpty ? name[0] : '?',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.badge_outlined,
                                                    size: 16,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'ID: $id',
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    size: 16,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$age años',
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar',
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: theme.colorScheme.error,
                                          ),
                                          onPressed: () async {
                                            int? count;
                                            final api = ApiService();
                                            final intId = int.tryParse(id);
                                            if (intId != null) {
                                              try {
                                                count = await api
                                                    .getSessionsCountForPatient(
                                                      intId,
                                                    );
                                              } catch (_) {
                                                count = null;
                                              }
                                            }
                                            if (!context.mounted) return;
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Eliminar paciente',
                                                ),
                                                content: Text(
                                                  count == null
                                                      ? '¿Seguro que deseas eliminar a "$name"? Esta acción es permanente.'
                                                      : 'Vas a eliminar a "$name" y $count sesión(es) asociada(s). Esta acción es permanente.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(false),
                                                    child: const Text(
                                                      'Cancelar',
                                                    ),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(true),
                                                    style:
                                                        FilledButton.styleFrom(
                                                          backgroundColor: theme
                                                              .colorScheme
                                                              .error,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text(
                                                      'Eliminar',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (!mounted) return;
                                            if (confirmed != true) return;
                                            try {
                                              if (intId != null) {
                                                await api.deletePatient(intId);
                                              }
                                              if (!mounted) return;
                                              if (mounted) {
                                                setState(() {
                                                  _patients.removeWhere(
                                                    (p) =>
                                                        p['id']?.toString() ==
                                                        id,
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
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (!mounted) return;
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'No se pudo eliminar: $e',
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    backgroundColor:
                                                        theme.colorScheme.error,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: theme.colorScheme.outline,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

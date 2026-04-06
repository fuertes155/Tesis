part of 'doctor_panel_screen.dart';

class DoctorPanelScreenState extends State<DoctorPanelScreen> {
  final _api = ApiService();
  bool _loading = true;
  String _query = '';
  Map<String, dynamic>? _me;
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final me = await _api.getMe();
      final patients = await _api.getPatients();
      if (!mounted) return;
      setState(() {
        _me = me;
        _patients = patients;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar panel: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleAvailability() async {
    final userId = _api.currentUserId ?? (_me?['id'] as int?);
    final isAvailable = (_me?['is_available'] ?? true) as bool;
    if (userId == null) return;
    try {
      await _api.updateUserAvailability(userId, !isAvailable);
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar disponibilidad: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openLatestResults(int patientId) async {
    final future = _api.getLatestResultsForPatient(patientId);
    if (!mounted) return;
    context.go('/results', extra: {'dataFuture': future});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = _me;
    final idObj = me == null ? null : me['id'];
    final int? myId =
        _api.currentUserId ?? (idObj is int ? idObj : int.tryParse('$idObj'));
    final bool isAvailable = (me?['is_available'] ?? true) as bool;
    final username =
        me?['username']?.toString() ?? _api.currentUsername ?? 'Doctor';

    final assigned = myId == null
        ? <dynamic>[]
        : _patients.where((p) {
            final did = p['doctor_id'];
            final int? pid = did is int
                ? did
                : (did is String ? int.tryParse(did) : null);
            return pid == myId;
          }).toList();

    final filtered = assigned.where((p) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      final name = (p['name'] ?? '').toString().toLowerCase();
      final diag = (p['diagnosis'] ?? '').toString().toLowerCase();
      return name.contains(q) || diag.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Panel Médico'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final horizontal = w < 640 ? 16.0 : 24.0;
                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal,
                    vertical: 24,
                  ),
                  children: [
                    PageContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderCard(
                                username: username,
                                isAvailable: isAvailable,
                                onToggleAvailability: _toggleAvailability,
                              )
                              .animate()
                              .fadeIn(duration: 220.ms)
                              .moveY(begin: 6, end: 0),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: w < 640 ? double.infinity : null,
                                child: _KpiCard(
                                  title: 'Pacientes asignados',
                                  value: '${assigned.length}',
                                  icon: Icons.people_alt_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              SizedBox(
                                width: w < 640 ? double.infinity : null,
                                child: _KpiCard(
                                  title: 'Disponibilidad',
                                  value: isAvailable
                                      ? 'Disponible'
                                      : 'No disponible',
                                  icon: isAvailable
                                      ? Icons.check_circle_outline
                                      : Icons.do_not_disturb_on_outlined,
                                  color: isAvailable
                                      ? const Color(0xFF10B981)
                                      : theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 220.ms, delay: 50.ms),
                          const SizedBox(height: 24),
                          Text(
                            'Mis Pacientes',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre o diagnóstico...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: 16),
                          if (filtered.isEmpty)
                            _EmptyPatientsCard().animate().fadeIn(
                              duration: 200.ms,
                            )
                          else
                            ...filtered.map((p) {
                              final idVal = p['id'];
                              final int? patientId = idVal is int
                                  ? idVal
                                  : int.tryParse('$idVal');
                              return _PatientRowCard(
                                    patient: p as Map<String, dynamic>,
                                    onStartSession: patientId == null
                                        ? null
                                        : () => context.push(
                                            '/new_session',
                                            extra: {'patientId': patientId},
                                          ),
                                    onViewLatestResults: patientId == null
                                        ? null
                                        : () => _openLatestResults(patientId),
                                  )
                                  .animate()
                                  .fadeIn(duration: 220.ms)
                                  .moveY(begin: 6, end: 0);
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String username;
  final bool isAvailable;
  final VoidCallback onToggleAvailability;

  const _HeaderCard({
    required this.username,
    required this.isAvailable,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;
            final status = Column(
              crossAxisAlignment: isNarrow
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  isAvailable ? 'Disponible' : 'No disponible',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isAvailable
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 6),
                Switch(
                  value: isAvailable,
                  onChanged: (_) => onToggleAvailability(),
                  activeThumbColor: const Color(0xFF10B981),
                ),
              ],
            );

            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rol: Doctor',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: info),
                    ],
                  ),
                  const SizedBox(height: 12),
                  status,
                ],
              );
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: info),
                status,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientRowCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback? onStartSession;
  final VoidCallback? onViewLatestResults;

  const _PatientRowCard({
    required this.patient,
    required this.onStartSession,
    required this.onViewLatestResults,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = patient['name']?.toString() ?? 'Paciente';
    final age = patient['age']?.toString();
    final diagnosis = patient['diagnosis']?.toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;
            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          if (age != null)
                            _Tag(
                              text: '$age años',
                              color: theme.colorScheme.primary,
                            ),
                          if (diagnosis != null && diagnosis.trim().isNotEmpty)
                            _Tag(
                              text: diagnosis,
                              color: theme.colorScheme.tertiary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            height: 40,
                            child: FilledButton(
                              onPressed: onStartSession,
                              child: const Text('Iniciar'),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: onViewLatestResults,
                              child: const Text('Resultados'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                if (age != null)
                                  _Tag(
                                    text: '$age años',
                                    color: theme.colorScheme.primary,
                                  ),
                                if (diagnosis != null &&
                                    diagnosis.trim().isNotEmpty)
                                  _Tag(
                                    text: diagnosis,
                                    color: theme.colorScheme.tertiary,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          SizedBox(
                            height: 40,
                            child: FilledButton(
                              onPressed: onStartSession,
                              child: const Text('Iniciar'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: onViewLatestResults,
                              child: const Text('Resultados'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EmptyPatientsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No tienes pacientes asignados todavía.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

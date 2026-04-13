part of 'doctor_panel_screen.dart';

class DoctorPanelScreenState extends State<DoctorPanelScreen> {
  final _api = GetIt.I<ApiService>();
  bool _loading = true;
  String _query = '';
  User? _me;
  List<Patient> _patients = [];

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
    final me = _me;
    if (me == null) return;
    try {
      await _api.updateUserAvailability(me.id, !me.isAvailable);
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
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final r = context.radii;
    final sem = context.sem;
    final me = _me;
    final int? myId = _api.currentUserId ?? me?.id;
    final bool isAvailable = me?.isAvailable ?? true;
    final username = me?.username ?? _api.currentUsername ?? 'Doctor';

    final assigned = myId == null
        ? <Patient>[]
        : _patients.where((p) {
            return p.doctorId == myId;
          }).toList();

    final filtered = assigned.where((p) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      final name = p.name.toLowerCase();
      final diag = (p.diagnosis ?? '').toLowerCase();
      return name.contains(q) || diag.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Panel Médico'),
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _fetch,
            icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
          ),
          SizedBox(width: spacing.sm),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final horizontal = w < 640 ? spacing.lg : spacing.xl;
                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal,
                    vertical: spacing.xl,
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
                          SizedBox(height: spacing.md),
                          Wrap(
                            spacing: spacing.md,
                            runSpacing: spacing.md,
                            children: [
                              SizedBox(
                                width: w < 640 ? double.infinity : null,
                                child: _KpiCard(
                                  title: 'Pacientes asignados',
                                  value: '${assigned.length}',
                                  icon: Icons.people_alt_outlined,
                                  color: cs.primary,
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
                                      ? sem.success
                                      : sem.danger,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 220.ms, delay: 50.ms),
                          SizedBox(height: spacing.x2l),
                          Text(
                            'Mis Pacientes',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          SizedBox(height: spacing.sm),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre o diagnóstico...',
                              hintStyle: TextStyle(color: cs.onSurfaceVariant),
                              prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
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
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          SizedBox(height: spacing.lg),
                          if (filtered.isEmpty)
                            _EmptyPatientsCard().animate().fadeIn(
                              duration: 200.ms,
                            )
                          else
                            ...filtered.map((p) {
                              final int patientId = p.id;
                              return _PatientRowCard(
                                    patient: p,
                                    onStartSession: () => context.push(
                                      '/new_session',
                                      extra: {'patientId': patientId},
                                    ),
                                    onViewLatestResults: () =>
                                        _openLatestResults(patientId),
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
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final sem = context.sem;
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: r.radiusLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
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
                        ? sem.success
                        : sem.danger,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Switch(
                  value: isAvailable,
                  onChanged: (_) => onToggleAvailability(),
                  activeColor: sem.success,
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
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacing.xs - 4),
                Text(
                  'Rol: Doctor',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
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
                        backgroundColor: cs.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          color: cs.primary,
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(child: info),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  status,
                ],
              );
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primary.withValues(
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
  final Patient patient;
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
    final name = patient.name;
    final age = patient.age;
    final diagnosis = patient.diagnosis;

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

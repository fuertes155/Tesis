part of 'doctor_panel_screen.dart';

class DoctorPanelScreenState extends ConsumerState<DoctorPanelScreen> {
  // Field _api removed, will use ref.read(apiServiceProvider.future)
  String _query = '';

  @override
  void initState() {
    super.initState();
    // No necesitamos fetch manual, Riverpod se encarga
  }

  Future<void> _fetch() async {
    ref.invalidate(currentUserProvider);
    ref.invalidate(patientsProvider);
  }

  Future<void> _toggleAvailability() async {
    final meAsync = ref.read(currentUserProvider);
    if (!meAsync.hasValue) return;
    final me = meAsync.value!;
    try {
      final api = await ref.read(apiServiceProvider.future);
      await api.updateUserAvailability(me.id, !me.isAvailable);
      ref.invalidate(currentUserProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar disponibilidad: $e')),
      );
    }
  }

  Future<void> _openLatestResults(int patientId) async {
    final api = await ref.read(apiServiceProvider.future);
    final future = api.getLatestResultsForPatient(patientId);
    if (!mounted) return;
    context.push('/results', extra: {'dataFuture': future});
  }

  @override
  Widget build(BuildContext context) {
    final meAsync = ref.watch(currentUserProvider);
    final patientsAsync = ref.watch(assignedPatientsProvider);
    
    return meAsync.when(
      loading: () => _buildScaffold(context, isLoading: true, me: null, assigned: []),
      error: (e, _) => _buildScaffold(context, isLoading: false, me: null, assigned: []),
      data: (User me) => patientsAsync.when(
        loading: () => _buildScaffold(context, isLoading: true, me: me, assigned: []),
        error: (e, _) => _buildScaffold(context, isLoading: false, me: me, assigned: []),
        data: (List<Patient> patients) {
          final filtered = patients.where((p) {
            final matchesName = SearchUtils.matches(p.name, _query);
            final matchesDiagnosis = SearchUtils.matches(p.diagnosis ?? '', _query);
            return matchesName || matchesDiagnosis;
          }).toList();
          return _buildScaffold(context, isLoading: false, me: me, assigned: filtered, totalAssigned: patients.length);
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, {required bool isLoading, required User? me, required List<Patient> assigned, int totalAssigned = 0}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final sem = context.sem;
    final glass = context.glass;
    
    final bool isAvailable = me?.isAvailable ?? true;
    final username = me?.username ?? ref.watch(apiServiceProvider).value?.currentUsername ?? 'Doctor';

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar premium ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                onPressed: _fetch,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Cerrar Sesión',
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
              SizedBox(width: spacing.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _DoctorPanelHero(
                username: username,
                isAvailable: isAvailable,
                sem: sem,
                glass: glass,
                onToggle: _toggleAvailability,
              ),
            ),
          ),

          // ── Cuerpo ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: isLoading
                ? Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      children: [
                        _ShimmerDoctorKpi(),
                        SizedBox(height: spacing.lg),
                        ...List.generate(
                          3,
                          (i) => Padding(
                            padding: EdgeInsets.only(bottom: spacing.md),
                            child: _ShimmerPatientCard(),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Row
                        _KpiRow(
                          assigned: totalAssigned,
                          isAvailable: isAvailable,
                          sem: sem,
                        ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.08),
                        SizedBox(height: spacing.lg),

                        // Header sección pacientes
                        _SectionHeader(
                          icon: Icons.people_alt_outlined,
                          label: 'MIS PACIENTES',
                          badge: '${assigned.length}',
                        ).animate().fadeIn(delay: 100.ms),
                        SizedBox(height: spacing.md),

                        // Búsqueda
                        TextField(
                          decoration: AppDecorations.glassInput(
                            label: 'Buscar paciente',
                            hint: 'Buscar por nombre o diagnóstico...',
                            prefixIcon: Icons.search_rounded,
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ).animate().fadeIn(delay: 150.ms),
                        SizedBox(height: spacing.lg),

                        // Lista de pacientes
                        if (assigned.isEmpty)
                          _EmptyPatientsCard()
                              .animate()
                              .fadeIn(duration: 200.ms)
                        else
                          ...assigned.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final p = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(bottom: spacing.md),
                              child: _PatientRowCard(
                                patient: p,
                                onStartSession: () => context.push(
                                  '/new_session',
                                  extra: {'patientId': p.id},
                                ),
                                onViewLatestResults: () =>
                                    _openLatestResults(p.id),
                              )
                                  .animate()
                                  .fadeIn(
                                    duration: 220.ms,
                                    delay: Duration(milliseconds: idx * 60),
                                  )
                                  .slideY(begin: 0.06, end: 0),
                            );
                          }),
                        SizedBox(height: spacing.xl),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Hero del panel del doctor ─────────────────────────────────────────────────

class _DoctorPanelHero extends StatelessWidget {
  const _DoctorPanelHero({
    required this.username,
    required this.isAvailable,
    required this.sem,
    required this.glass,
    required this.onToggle,
  });
  final String username;
  final bool isAvailable;
  final AppSemanticColors sem;
  final AppGlass glass;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Container(
      decoration: BoxDecoration(gradient: glass.headerGradient),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.x2l,
            spacing.lg,
            spacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar con pulso de disponibilidad
                  _AvailabilityPulse(isAvailable: isAvailable, sem: sem),
                  SizedBox(width: spacing.lg),

                  // Nombre y rol
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Panel Médico',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Toggle de disponibilidad
                  _CompactAvailabilityToggle(
                    isAvailable: isAvailable,
                    onToggle: onToggle,
                    sem: sem,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sección header reutilizable ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, this.badge});
  final IconData icon;
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Pulso de disponibilidad ───────────────────────────────────────────────────

class _AvailabilityPulse extends StatelessWidget {
  final bool isAvailable;
  final AppSemanticColors sem;
  const _AvailabilityPulse({required this.isAvailable, required this.sem});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isAvailable)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sem.success.withValues(alpha: 0.18),
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.35, 1.35),
                duration: 1400.ms,
                curve: Curves.easeOut,
              ).then().scale(
                begin: const Offset(1.35, 1.35),
                end: const Offset(1, 1),
                duration: 1400.ms,
              ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }
}

// ── Toggle compacto ───────────────────────────────────────────────────────────

class _CompactAvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onToggle;
  final AppSemanticColors sem;
  const _CompactAvailabilityToggle({
    required this.isAvailable,
    required this.onToggle,
    required this.sem,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? sem.success : sem.danger;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isAvailable ? 'Disponible' : 'Ocupado',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de KPIs ─────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final int assigned;
  final bool isAvailable;
  final AppSemanticColors sem;
  const _KpiRow({
    required this.assigned,
    required this.isAvailable,
    required this.sem,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Row(
      children: [
        // KPI: Pacientes
        Expanded(
          child: Container(
            padding: EdgeInsets.all(spacing.lg),
            decoration: AppDecorations.premiumCard(context, radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.15),
                        cs.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.people_alt_outlined, color: cs.primary, size: 22),
                ),
                SizedBox(height: spacing.md),
                Text(
                  '$assigned',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Pacientes asignados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: spacing.md),

        // KPI: Disponibilidad
        Expanded(
          child: Container(
            padding: EdgeInsets.all(spacing.lg),
            decoration: AppDecorations.premiumCard(context, radius: 16).copyWith(
              border: Border.all(
                color: (isAvailable ? sem.success : sem.danger).withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isAvailable ? sem.success : sem.danger)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isAvailable
                        ? Icons.check_circle_outline
                        : Icons.do_not_disturb_on_outlined,
                    color: isAvailable ? sem.success : sem.danger,
                    size: 22,
                  ),
                ),
                SizedBox(height: spacing.md),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isAvailable ? 'Disponible' : 'No disponible',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isAvailable ? sem.success : sem.danger,
                    ),
                  ),
                ),
                Text(
                  'Estado actual',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Patient Row Card ──────────────────────────────────────────────────────────

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
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final name = patient.name;
    final age = patient.age;
    final diagnosis = patient.diagnosis;
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Container(
      decoration: AppDecorations.premiumCard(context, radius: 16),
      child: ClipRRect(
        borderRadius: r.radiusLg,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Accent bar premium con gradiente
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [cs.primary, cs.tertiary],
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 480;

                      final info = Row(
                        children: [
                          // Avatar con gradiente
                          Hero(
                            tag: 'avatar_patient_${patient.id}',
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cs.primary.withValues(alpha: 0.20),
                                    cs.tertiary.withValues(alpha: 0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'name_patient_${patient.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                SizedBox(height: spacing.xs - 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      StatusBadge(
                                        label: '$age años', 
                                        color: cs.primary, 
                                        small: true
                                      ),
                                      if (diagnosis != null &&
                                          diagnosis.trim().isNotEmpty)
                                        StatusBadge(
                                          label: diagnosis,
                                          color: cs.tertiary,
                                          small: true,
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final actions = Wrap(
                        spacing: spacing.sm,
                        runSpacing: spacing.sm,
                        children: [
                          SizedBox(
                            height: 44,
                            child: PremiumButton(
                              onPressed: onStartSession ?? () {},
                              icon: Icons.play_arrow_rounded,
                              label: 'Iniciar',
                            ),
                          ),
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: onViewLatestResults,
                              icon: const Icon(Icons.analytics_outlined, size: 18),
                              label: const Text('Resultados'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            info,
                            SizedBox(height: spacing.md),
                            actions,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: info),
                          SizedBox(width: spacing.md),
                          actions,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPatientsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: EmptyStateView(
        iconData: Icons.inbox_outlined,
        title: 'Sin pacientes asignados',
        description: 'Cuando se te asignen pacientes, aparecerán aquí.',
      ),
    );
  }
}

// ── Shimmer widgets ───────────────────────────────────────────────────────────

class _ShimmerDoctorKpi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      children: [
        Expanded(child: SkeletonLoader(width: double.infinity, height: 110, borderRadius: context.radii.lg)),
        SizedBox(width: spacing.md),
        Expanded(child: SkeletonLoader(width: double.infinity, height: 110, borderRadius: context.radii.lg)),
      ],
    );
  }
}

class _ShimmerPatientCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const PatientCardSkeleton();
  }
}

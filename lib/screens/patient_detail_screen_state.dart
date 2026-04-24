part of 'patient_detail_screen.dart';

class _PatientDetailState extends ConsumerState<PatientDetailScreen> {
  int? _currentPatientId;
  String _currentPatientName = '';
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _recentSessions = [];
  List<dynamic> _allPatients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentPatientId = widget.patientId;
    _currentPatientName = widget.patientName;
    _fetchData();
  }

  Future<void> _fetchData({bool refreshPatients = true}) async {
    if (_currentPatientId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final api = await ref.read(apiServiceProvider.future);
      if (refreshPatients) {
        _allPatients = await api.getPatients();
      }
      final sessions = await api.getSessions();
      
      final patient = _allPatients.firstWhere(
        (p) => p.id == _currentPatientId,
        orElse: () => _allPatients.first,
      );
      
      final patientSessions = sessions
          .where((s) => s.patientId == _currentPatientId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
        
      if (!mounted) return;
      setState(() {
        _currentPatientName = patient.name;
        _patientData = {
          'name': patient.name,
          'age': patient.age,
          'id': patient.id,
          'diagnosis': patient.diagnosis ?? 'Sin diagnóstico',
          'doctor_id': patient.doctorId,
        };
        _recentSessions = patientSessions
            .take(5)
            .map((s) => {
                  'id': s.id,
                  'date': DateFormat('dd/MM/yyyy').format(s.date),
                  'status': s.status,
                  'notes': s.notes,
                })
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changePatient(int id, String name) {
    if (_currentPatientId == id) return;
    setState(() {
      _currentPatientId = id;
      _currentPatientName = name;
    });
    _fetchData(refreshPatients: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(flex: 4, child: _buildMasterView(context)),
                const VerticalDivider(width: 1),
                Expanded(flex: 8, child: _buildDetailView(context)),
              ],
            );
          }
          return _buildDetailView(context);
        },
      ),
    );
  }

  Widget _buildMasterView(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final glass = context.glass;
    final r = context.radii;
    final spacing = context.spacing;

    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(gradient: glass.headerGradient),
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.xl + 20, spacing.lg, spacing.md),
            width: double.infinity,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Directorio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, 
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _allPatients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(spacing.md),
                    itemCount: _allPatients.length,
                    itemBuilder: (context, index) {
                      final p = _allPatients[index];
                      final isSelected = p.id == _currentPatientId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: r.radiusMd,
                          border: Border.all(
                            color: isSelected ? cs.primary.withValues(alpha: 0.4) : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: r.radiusMd),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? cs.primary : cs.onSurface,
                            ),
                          ),
                          subtitle: Text('ID: #${p.id}'),
                          onTap: () => _changePatient(p.id, p.name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final sem = context.sem;

    return CustomScrollView(
        slivers: [
          // ── SliverAppBar con avatar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: cs.primary,
            surfaceTintColor: cs.primary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: Hero(
                tag: 'hero_icon_new_session_placeholder', // Or another tag or none
                flightShuttleBuilder: (flightCtx, animation, direction, fromCtx, toCtx) {
                  return Material(color: Colors.transparent, child: toCtx.widget);
                },
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (_currentPatientId != null &&
                  ref.watch(apiServiceProvider).value?.currentRole == 'gestor')
                IconButton(
                  tooltip: 'Eliminar Paciente',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  onPressed: () => _confirmDelete(context, cs, sem),
                ),
              SizedBox(width: spacing.xs),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: context.glass.headerGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(spacing.lg, spacing.xl, spacing.lg, spacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Avatar premium con gradiente
                            Hero(
                              tag: 'avatar_patient_${_currentPatientId ?? ""}',
                              flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                                return Material(color: Colors.transparent, child: toHeroContext.widget);
                              },
                              child: _buildAvatar(_currentPatientName, cs),
                            ),
                            SizedBox(width: spacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag: 'name_patient_${_currentPatientId ?? ""}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        _currentPatientName,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: spacing.xs - 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                    ),
                                    child: Text(
                                      'Expediente del Paciente',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Cuerpo ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _loading
                ? Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailSkeleton(),
                        SizedBox(height: spacing.x2l),
                        _DetailSkeleton(height: 80),
                        SizedBox(height: spacing.x2l),
                        _DetailSkeleton(height: 60),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Info card ──────────────────────────────────────
                        _InfoCard(
                          patientData: _patientData,
                          patientId: _currentPatientId,
                        ).animate(key: ValueKey(_currentPatientId)).fadeIn().slideY(begin: 0.1),
                        SizedBox(height: spacing.x2l),

                        // ── Acciones rápidas ──────────────────────────────
                        _SectionLabel(label: 'ACCIONES RÁPIDAS', icon: Icons.flash_on_rounded),
                        SizedBox(height: spacing.lg),
                        _ActionsGrid(patientId: _currentPatientId)
                            .animate(key: ValueKey('actions_$_currentPatientId'))
                            .fadeIn(delay: 150.ms)
                            .slideY(begin: 0.1),
                        SizedBox(height: spacing.x2l),

                        // ── Sesiones recientes o Estado Vacío ───────────────
                        if (_recentSessions.isNotEmpty) ...[
                          _SectionLabel(label: 'SESIONES RECIENTES', icon: Icons.history_rounded),
                          SizedBox(height: spacing.lg),
                          ..._recentSessions.asMap().entries.map((e) {
                            final idx = e.key;
                            final s = e.value;
                            final isCompleted = (s['status'] ?? '') == 'completed';
                            final statusColor = isCompleted ? sem.success : sem.warning;
                            return Padding(
                              padding: EdgeInsets.only(bottom: spacing.sm),
                              child: _SessionMiniCard(
                                session: s,
                                statusColor: statusColor,
                                isCompleted: isCompleted,
                                onTap: () => context.push(
                                  '/results',
                                  extra: {'dataFuture': Future.value(_toResultData(s))},
                                ),
                              ).animate().fadeIn(delay: Duration(milliseconds: 200 + idx * 60)).slideX(begin: 0.08),
                            );
                          }),
                        ] else ...[
                          _SectionLabel(label: 'SESIONES RECIENTES', icon: Icons.history_rounded),
                          SizedBox(height: spacing.lg),
                          SizedBox(
                            height: 200,
                            child: EmptyStateView(
                              title: 'Sin Evaluaciones',
                              description: 'Este paciente aún no registra actividad cognitiva.',
                              iconData: Icons.history_toggle_off_rounded,
                              buttonLabel: 'Iniciar Evaluación',
                              onButtonPressed: () => context.push('/new_session', extra: {'patientId': _currentPatientId}),
                            ),
                          ),
                        ],
                        SizedBox(height: spacing.xl),
                      ],
                    ),
                  ),
          ),
        ],
      );
  }

  Map<String, dynamic> _toResultData(Map<String, dynamic> s) {
    return {
      'title': 'Resultados - Sesión #${s['id']}',
      'score': 70,
      'details': {'General': 70},
    };
  }

  Widget _buildAvatar(String name, ColorScheme cs) {
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    final avatarColor = HSLColor.fromAHSL(1.0, hue, 0.55, 0.45).toColor();
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            avatarColor.withValues(alpha: 0.70),
            avatarColor.withValues(alpha: 0.40),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ColorScheme cs, AppSemanticColors sem) async {
    int? count;
    try {
      if (_currentPatientId != null) {
        final api = await ref.read(apiServiceProvider.future);
        count = await api.getSessionsCountForPatient(_currentPatientId!);
      }
    } catch (_) {}
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar paciente'),
        content: Text(
          count == null
              ? '¿Seguro que deseas eliminar a "$_currentPatientName"? Esta acción es permanente.'
              : 'Vas a eliminar a "$_currentPatientName" y $count sesión(es) asociada(s). Esta acción es permanente.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: sem.danger, foregroundColor: cs.onError),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed != true) return;
    try {
      final api = await ref.read(apiServiceProvider.future);
      await api.deletePatient(_currentPatientId!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Paciente eliminado correctamente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: sem.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo eliminar: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: sem.danger,
          ),
        );
      }
    }
  }
}

// ── Detail Skeleton ───────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  final double height;
  const _DetailSkeleton({this.height = 120});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? const Color(0xFF0F1F38) : const Color(0xFFE2EFF8);
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(20),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: isDark
              ? const Color(0xFF1A3050)
              : const Color(0xFFEFF8FF),
        );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Map<String, dynamic>? patientData;
  final int? patientId;
  const _InfoCard({this.patientData, this.patientId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final r = context.radii;
    final spacing = context.spacing;
    final glass = context.glass;
    final data = patientData;

    return Container(
      decoration: BoxDecoration(
        gradient: glass.cardGradient,
        borderRadius: r.radiusXl,
        border: Border.all(color: glass.borderColor, width: 1),
        boxShadow: context.premiumShadows,
      ),
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'ID Único',
            value: data != null ? '#${data['id']}' : (patientId?.toString() ?? 'No asignado'),
            color: cs.tertiary,
          ),
          Divider(height: 24, color: glass.borderColor),
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Edad',
            value: data != null ? '${data['age']} años' : '—',
            color: const Color(0xFF8B5CF6),
          ),
          Divider(height: 24, color: glass.borderColor),
          _InfoRow(
            icon: Icons.medical_information_outlined,
            label: 'Diagnóstico',
            value: data != null ? (data['diagnosis'] ?? 'Pendiente') : '—',
            color: cs.primary,
            valueColor: data != null && (data['diagnosis'] ?? '').toString().isNotEmpty
                ? cs.primary
                : cs.onSurfaceVariant,
          ),
          Divider(height: 24, color: glass.borderColor),
          _InfoRow(
            icon: Icons.person_outlined,
            label: 'Doctor asignado',
            value: data?['doctor_id'] != null ? 'Asignado' : 'Sin asignar',
            color: const Color(0xFF10B981),
            valueColor: data?['doctor_id'] != null
                ? (theme.extension<AppSemanticColors>()?.success ?? Colors.green)
                : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.color, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.06)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  final int? patientId;
  const _ActionsGrid({this.patientId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sem = context.sem;
    final spacing = context.spacing;

    final actions = [
      _ActionItem(
        icon: Icons.play_circle_outline_rounded,
        label: 'Iniciar Sesión',
        subtitle: 'Nueva evaluación',
        color: cs.primary,
        isPrimary: true,
        onTap: () => context.push('/new_session', extra: {'patientId': patientId}),
      ),
      _ActionItem(
        icon: Icons.history_rounded,
        label: 'Ver Historial',
        subtitle: 'Sesiones pasadas',
        color: cs.tertiary,
        isPrimary: false,
        onTap: () => context.push('/history'),
      ),
      _ActionItem(
        icon: Icons.analytics_outlined,
        label: 'Resultados',
        subtitle: 'Última evaluación',
        color: sem.info,
        isPrimary: false,
        onTap: () => context.push('/history'),
      ),
      _ActionItem(
        icon: Icons.ios_share_rounded,
        label: 'Exportar',
        subtitle: 'Datos del paciente',
        color: cs.onSurfaceVariant,
        isPrimary: false,
        onTap: () {},
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: spacing.md,
      crossAxisSpacing: spacing.md,
      childAspectRatio: 2.0,
      children: actions.map((a) => _ActionCard(item: a)).toList(),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isPrimary,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;
  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final r = context.radii;
    final spacing = context.spacing;
    final glass = context.glass;

    final decoration = item.isPrimary
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: r.radiusMd,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          )
        : BoxDecoration(
            gradient: glass.cardGradient,
            borderRadius: r.radiusMd,
            border: Border.all(color: glass.borderColor, width: 1),
          );

    return InkWell(
      onTap: item.onTap,
      borderRadius: r.radiusMd,
      splashColor: item.color.withValues(alpha: 0.06),
      child: Container(
        padding: EdgeInsets.all(spacing.md),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: item.isPrimary
                    ? LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.10),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          item.color.withValues(alpha: 0.18),
                          item.color.withValues(alpha: 0.06),
                        ],
                      ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (item.isPrimary ? Colors.white : item.color)
                      .withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                item.icon,
                color: item.isPrimary ? Colors.white : item.color,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: item.isPrimary ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: item.isPrimary
                        ? Colors.white.withValues(alpha: 0.75)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionMiniCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final Color statusColor;
  final bool isCompleted;
  final VoidCallback onTap;

  const _SessionMiniCard({
    required this.session,
    required this.statusColor,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final r = context.radii;
    final spacing = context.spacing;

    final glass = context.glass;
    return Material(
      color: Colors.transparent,
      borderRadius: r.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: r.radiusMd,
        splashColor: cs.primary.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            gradient: glass.cardGradient,
            borderRadius: r.radiusMd,
            border: Border.all(color: glass.borderColor, width: 1),
            boxShadow: context.premiumShadows,
          ),
          child: ClipRRect(
            borderRadius: r.radiusMd,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Accent bar gradient
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [statusColor, statusColor.withValues(alpha: 0.40)],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.md),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary.withValues(alpha: 0.14),
                                  cs.primary.withValues(alpha: 0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
                            ),
                            child: Icon(Icons.assignment_outlined, color: cs.primary, size: 18),
                          ),
                          SizedBox(width: spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sesión #${session['id']}',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  session['date']?.toString() ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.20)),
                            ),
                            child: Text(
                              isCompleted ? 'Completada' : 'En Progreso',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          SizedBox(width: spacing.sm),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: cs.outline),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

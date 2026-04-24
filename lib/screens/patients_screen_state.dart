part of 'patients_screen.dart';

class PatientsScreenState extends ConsumerState<PatientsScreen> {
  String _searchQuery = '';
  String? _noticeBanner;

  @override
  void initState() {
    super.initState();
    _initLogic();
  }

  Future<void> _initLogic() async {
    final api = await ref.read(apiServiceProvider.future);
    if (api.currentRole == 'user') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/test_selector');
      });
    } else {
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
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final patientsAsync = ref.watch(patientsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: patientsAsync.when(
        loading: () => _buildCustomScroll(context, isLoading: true, patients: []),
        error: (err, _) => _buildCustomScroll(context, patients: []),
        data: (patientsList) {
          final filtered = patientsList
              .where((p) => SearchUtils.matches(p.name, _searchQuery))
              .toList();
          return _buildCustomScroll(context, patients: filtered);
        },
      ),
    );
  }  Widget _buildCustomScroll(BuildContext context, {bool isLoading = false, required List<Patient> patients}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final sem = context.sem;
    final apiValue = ref.watch(apiServiceProvider).value;
    final role = apiValue?.currentRole;
    final canDelete = role == 'gestor';

    return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: cs.surfaceContainerLowest,
            surfaceTintColor: cs.surfaceContainerLowest,
            elevation: 0,
            centerTitle: false,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Hero(
                  tag: 'hero_icon_patients',
                  flightShuttleBuilder: (flightCtx, animation, direction, fromCtx, toCtx) {
                    return Material(color: Colors.transparent, child: toCtx.widget);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.arrow_back_rounded, color: cs.secondary, size: 20),
                  ),
                ),
                onPressed: () => context.pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                left: spacing.lg + 36,
                bottom: spacing.md,
              ),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Pacientes',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!isLoading) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${patients.length}',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (role == 'gestor')
                Padding(
                  padding: EdgeInsets.only(right: spacing.md),
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await context.push('/create_patient');
                      if (!mounted) return;
                      if (result == true) {
                        ref.invalidate(patientsProvider);
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nuevo'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
            ],
          ),

          // ── Banner de aviso ───────────────────────────────────────────────
          if (_noticeBanner != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    spacing.lg, spacing.lg, spacing.lg, 0),
                child: Container(
                  padding: EdgeInsets.all(spacing.md),
                  decoration: BoxDecoration(
                    color: sem.info.withValues(alpha: 0.08),
                    borderRadius: r.radiusMd,
                    border:
                        Border.all(color: sem.info.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: sem.info),
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
                        icon: Icon(Icons.close_rounded, color: sem.info),
                        onPressed: () =>
                            setState(() => _noticeBanner = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Barra de búsqueda ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Buscar paciente por nombre...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () =>
                              setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // ── Loading / vacío / lista ───────────────────────────────────────
          if (isLoading)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: EdgeInsets.only(bottom: spacing.sm),
                    child: _PatientCardSkeleton(),
                  ),
                  childCount: 5,
                ),
              ),
            )
          else if (patients.isEmpty)
            SliverFillRemaining(
              child: _EmptyPatientsState(hasSearch: _searchQuery.isNotEmpty),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final patient = patients[index];
                    final name = patient.name;
                    final id = patient.id.toString();
                    final age = patient.age.toString();
                    final intId = patient.id;

                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.sm),
                      child: _PatientCard(
                        name: name,
                        age: age,
                        id: id,
                        canDelete: canDelete,
                        onTap: () async {
                          final result = await context.push(
                            '/patient_detail',
                            extra: {'name': name, 'id': patient.id},
                          );
                          if (result == true) {
                            ref.invalidate(patientsProvider);
                            ref.invalidate(sessionsProvider);
                          }
                        },
                        onDelete: canDelete
                            ? () => _confirmDelete(
                                context, name, id, intId, sem, cs)
                            : null,
                      ),
                    ).animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideX(begin: 0.06);
                  },
                  childCount: patients.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String name,
    String id,
    int intId,
    AppSemanticColors sem,
    ColorScheme cs,
  ) async {
    int? count;
    try {
      final api = await ref.read(apiServiceProvider.future);
      count = await api.getSessionsCountForPatient(intId);
    } catch (_) {}
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar paciente'),
        content: Text(
          count == null
              ? '¿Seguro que deseas eliminar a "$name"? Esta acción es permanente.'
              : 'Vas a eliminar a "$name" y $count sesión(es). Esta acción es permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: sem.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      // Invalidad proveedores de Riverpod tras eliminación
      ref.invalidate(patientsProvider);
      ref.invalidate(sessionsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente eliminado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo eliminar: $e'),
            backgroundColor: sem.danger,
          ),
        );
      }
    }
  }
}

// ── Patient Card Premium ──────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.name,
    required this.age,
    required this.id,
    required this.canDelete,
    required this.onTap,
    this.onDelete,
  });

  final String name;
  final String age;
  final String id;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final r = context.radii;
    final spacing = context.spacing;
    final glass = context.glass;

    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    // Color del avatar basado en hash del nombre
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    final avatarColor = HSLColor.fromAHSL(1.0, hue, 0.55, 0.45).toColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: r.radiusMd,
        splashColor: cs.primary.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            gradient: glass.cardGradient,
            borderRadius: r.radiusMd,
            border: Border.all(color: glass.borderColor, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.lg,
              vertical: spacing.md,
            ),
            child: Row(
              children: [
                // Avatar con color único y gradiente
                Hero(
                  tag: 'avatar_patient_$id',
                  flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                    return Material(color: Colors.transparent, child: toHeroContext.widget);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          avatarColor.withValues(alpha: 0.80),
                          avatarColor.withValues(alpha: 0.50),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: spacing.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'name_patient_$id',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _MiniTag(text: '$age años', color: cs.primary),
                          const SizedBox(width: 6),
                          _MiniTag(text: 'ID: $id', color: cs.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),

                // Acciones
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: context.sem.danger.withValues(alpha: 0.7),
                        ),
                        onPressed: onDelete,
                        tooltip: 'Eliminar',
                      ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.80),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

// Skeleton card

class _PatientCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return SkeletonLoader(
      width: double.infinity,
      height: 72,
      borderRadius: context.radii.md,
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyPatientsState extends ConsumerWidget {
  const _EmptyPatientsState({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiValue = ref.watch(apiServiceProvider).value;
    final role = apiValue?.currentRole;
    return EmptyStateView(
      title: hasSearch ? 'Sin resultados' : 'Panel de Pacientes Vacío',
      description: hasSearch
          ? 'No encontramos ningún paciente con ese nombre. Prueba con otros términos.'
          : 'Aún no has registrado pacientes en el hospital. Comienza agregando uno para iniciar evaluaciones.',
      iconData: hasSearch ? Icons.search_off_rounded : Icons.person_add_outlined,
      buttonLabel: (!hasSearch && role == 'gestor') ? 'Registrar Primer Paciente' : null,
      onButtonPressed: (!hasSearch && role == 'gestor')
          ? () => context.push('/create_patient')
          : null,
    );
  }
}

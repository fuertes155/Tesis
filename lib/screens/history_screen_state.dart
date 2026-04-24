part of 'history_screen.dart';

class HistoryScreenState extends ConsumerState<HistoryScreen> {
  // _api field removed, using providers for data access
  String _query = '';

  @override
  void initState() {
    super.initState();
  }

  List<Session> _getFiltered(List<Session> sessions) {
    if (_query.isEmpty) return sessions;
    final q = _query.toLowerCase();
    return sessions.where((s) {
    return s.notes.toLowerCase().contains(q) ||
             (s.id.toString()).contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final sem = context.sem;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: cs.surfaceContainerLowest,
            surfaceTintColor: cs.surfaceContainerLowest,
            elevation: 0,
            centerTitle: false,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Hero(
                  tag: 'hero_icon_history',
                  flightShuttleBuilder: (flightCtx, animation, direction, fromCtx, toCtx) {
                    return Material(color: Colors.transparent, child: toCtx.widget);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.arrow_back_rounded, color: cs.tertiary, size: 20),
                  ),
                ),
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
                onPressed: () => ref.invalidate(sessionsProvider),
                tooltip: 'Actualizar',
              ),
              SizedBox(width: spacing.md),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: spacing.lg + 36, bottom: spacing.md),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HISTORIAL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Sesiones',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra de búsqueda
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
              child: TextFormField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por notas o ID...',
                  prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant, size: 18),
                          onPressed: () => setState(() => _query = ''),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Contenido principal
          sessionsAsync.when(
            loading: () => SliverPadding(
              padding: EdgeInsets.all(spacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: EdgeInsets.only(bottom: spacing.sm),
                    child: _SessionSkeleton(),
                  ),
                  childCount: 5,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Error: $e')),
            ),
            data: (sessions) {
              final filtered = _getFiltered(sessions);
              
              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    title: _query.isNotEmpty ? 'Sin resultados' : 'Historial Vacío',
                    description: _query.isNotEmpty
                        ? 'No hay sesiones que coincidan con tu búsqueda.'
                        : 'Aún no se han registrado sesiones para tus pacientes. Inicia una evaluación para ver los resultados aquí.',
                    iconData: _query.isNotEmpty ? Icons.search_off_rounded : Icons.history_toggle_off_rounded,
                    buttonLabel: _query.isEmpty ? 'Iniciar Nueva Sesión' : null,
                    onButtonPressed: _query.isEmpty ? () => context.push('/new_session') : null,
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.all(spacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final s = filtered[index];
                      final sessionNumber = s.id;
                      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(s.date);
                      final status = s.status.toLowerCase();
                      final isCompleted = status == 'completed' || status == 'completada';
                      final statusColor = isCompleted ? sem.success : sem.warning;
                      final statusLabel = isCompleted ? 'Completada' : 'En Progreso';
                      final notes = s.notes;
                      final gameType = _detectGameType(notes);

                      return Padding(
                        padding: EdgeInsets.only(bottom: spacing.sm),
                        child: _SessionCard(
                          sessionNumber: sessionNumber,
                          date: dateStr,
                          statusLabel: statusLabel,
                          statusColor: statusColor,
                          notes: notes,
                          gameType: gameType,
                          isCompleted: isCompleted,
                          onTap: () => context.push(
                            '/results',
                            extra: {'dataFuture': Future.value(_toResultData(s))},
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.06),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _detectGameType(String notes) {
    if (notes.startsWith('visual_memory')) return 'Memoria Visual';
    if (notes.startsWith('reaction')) return 'Atención';
    if (notes.startsWith('fluency')) return 'Fluidez Verbal';
    if (notes.startsWith('stroop')) return 'Funciones Ejecutivas';
    return 'Evaluación General';
  }

  Map<String, dynamic> _toResultData(Session s) {
    final notes = s.notes;
    if (notes.startsWith('visual_memory')) {
      return {'title': 'Resultados - Memoria Visual', 'score': 70, 'details': {'Memoria': 70, 'Atención': 65}};
    } else if (notes.startsWith('reaction')) {
      return {'title': 'Resultados - Atención', 'score': 65, 'details': {'Atención': 65, 'Funciones Ejecutivas': 60}};
    } else if (notes.startsWith('fluency')) {
      return {'title': 'Resultados - Lenguaje', 'score': 75, 'details': {'Lenguaje': 75, 'Memoria': 68}};
    } else if (notes.startsWith('stroop')) {
      return {'title': 'Resultados - Funciones Ejecutivas', 'score': 60, 'details': {'Funciones Ejecutivas': 60, 'Atención': 62}};
    }
    return {'title': 'Resultados', 'score': 70, 'details': {'General': 70}};
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final dynamic sessionNumber;
  final String date;
  final String statusLabel;
  final Color statusColor;
  final String notes;
  final String gameType;
  final bool isCompleted;
  final VoidCallback onTap;

  const _SessionCard({
    required this.sessionNumber,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
    required this.notes,
    required this.gameType,
    required this.isCompleted,
    required this.onTap,
  });

  IconData get _gameIcon {
    switch (gameType) {
      case 'Memoria Visual': return Icons.psychology_outlined;
      case 'Atención': return Icons.timer_outlined;
      case 'Fluidez Verbal': return Icons.record_voice_over_outlined;
      case 'Funciones Ejecutivas': return Icons.settings_suggest_outlined;
      default: return Icons.assignment_outlined;
    }
  }

  Color get _gameColor {
    switch (gameType) {
      case 'Memoria Visual': return const Color(0xFF8B5CF6);
      case 'Atención': return const Color(0xFF0EA5E9);
      case 'Fluidez Verbal': return const Color(0xFF10B981);
      case 'Funciones Ejecutivas': return const Color(0xFFF59E0B);
      default: return const Color(0xFF0A7EA4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final r = context.radii;
    final spacing = context.spacing;
    final glass = context.glass;
    final color = _gameColor;

    return Material(
      color: Colors.transparent,
      borderRadius: r.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: r.radiusMd,
        splashColor: color.withValues(alpha: 0.06),
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
                  // Gradient accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [statusColor, color],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Icon with gradient bg
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withValues(alpha: 0.18),
                                      color.withValues(alpha: 0.07),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: color.withValues(alpha: 0.15)),
                                ),
                                child: Icon(_gameIcon, color: color, size: 18),
                              ),
                              SizedBox(width: spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sesión #$sessionNumber',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
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
                                            statusLabel.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: statusColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      gameType,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (date.isNotEmpty) ...[
                            SizedBox(height: spacing.sm),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 13, color: cs.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  date,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                if (isCompleted) ...[
                                  Icon(Icons.check_circle_rounded, size: 14, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completada',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                SizedBox(width: spacing.xs),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: cs.outline),
                              ],
                            ),
                          ],
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

// ── Session Skeleton ──────────────────────────────────────────────────────────

class _SessionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SessionCardSkeleton();
  }
}

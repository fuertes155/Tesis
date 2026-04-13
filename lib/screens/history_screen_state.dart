part of 'history_screen.dart';

class HistoryScreenState extends State<HistoryScreen> {
  final _api = GetIt.I<ApiService>();
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getSessions();
      setState(() {
        _sessions = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _sessions;
    return _sessions
        .where(
          (s) => (s['notes'] ?? '').toString().toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final r = context.radii;
    final sem = context.sem;

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
                'Historial de Sesiones',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: _fetch,
                tooltip: 'Actualizar',
              ),
              SizedBox(width: spacing.md),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: TextFormField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por notas o ID...',
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
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 64,
                      color: cs.outline,
                    ),
                    SizedBox(height: spacing.md),
                    Text(
                      'No hay sesiones registradas',
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
                  final s = _filtered[index];
                  final sessionNumber = s['id'] ?? (index + 1);
                  final date = s['date']?.toString() ?? '';
                  final isCompleted = (s['status'] ?? '') == 'completed';

                  final statusColor = isCompleted
                      ? sem.success
                      : sem.warning;
                  final statusLabel = isCompleted
                      ? 'Completada'
                      : 'En Progreso';

                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.sm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: r.radiusMd,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: InkWell(
                        borderRadius: r.radiusMd,
                        onTap: () => context.push(
                          '/results',
                          extra: {'dataFuture': Future.value(_toResultData(s))},
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(spacing.lg - 4), // ~20
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(spacing.sm),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.05),
                                  borderRadius: r.radiusSm,
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: cs.primary,
                                ),
                              ),
                              SizedBox(width: spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sesión #$sessionNumber',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: cs.onSurface,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: spacing.sm - 2, // ~10
                                            vertical: spacing.xs - 4, // ~4
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: r.radiusLg,
                                          ),
                                          child: Text(
                                            statusLabel.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: statusColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing.xs - 4), // ~4
                                    Text(
                                      date,
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if ((s['notes'] ?? '')
                                        .toString()
                                        .isNotEmpty) ...[
                                      SizedBox(height: spacing.sm),
                                      Text(
                                        s['notes'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(width: spacing.xs),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: cs.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                }, childCount: _filtered.length),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _toResultData(Map<String, dynamic> s) {
    final notes = (s['notes'] ?? '').toString();
    if (notes.startsWith('visual_memory')) {
      return {
        'title': 'Resultados - Memoria Visual',
        'score': 70,
        'details': {'Memoria': 70, 'Atención': 65},
      };
    } else if (notes.startsWith('reaction')) {
      return {
        'title': 'Resultados - Atención',
        'score': 65,
        'details': {'Atención': 65, 'Funciones Ejecutivas': 60},
      };
    } else if (notes.startsWith('fluency')) {
      return {
        'title': 'Resultados - Lenguaje',
        'score': 75,
        'details': {'Lenguaje': 75, 'Memoria': 68},
      };
    } else if (notes.startsWith('stroop')) {
      return {
        'title': 'Resultados - Funciones Ejecutivas',
        'score': 60,
        'details': {'Funciones Ejecutivas': 60, 'Atención': 62},
      };
    }
    return {
      'title': 'Resultados',
      'score': 70,
      'details': {'General': 70},
    };
  }
}

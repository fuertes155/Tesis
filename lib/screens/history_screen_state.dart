part of 'history_screen.dart';

class HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
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
    final primaryColor = const Color(0xFF1A237E);

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
                'Historial de Sesiones',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                onPressed: _fetch,
                tooltip: 'Actualizar',
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TextFormField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por notas o ID...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
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
                    Icon(Icons.history_toggle_off_rounded, size: 64, color: const Color(0xFFCBD5E1)),
                    const SizedBox(height: 16),
                    Text(
                      'No hay sesiones registradas',
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final s = _filtered[index];
                    final sessionNumber = s['id'] ?? (index + 1);
                    final date = s['date']?.toString() ?? '';
                    final isCompleted = (s['status'] ?? '') == 'completed';

                    final statusColor = isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
                    final statusLabel = isCompleted ? 'Completada' : 'En Progreso';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push(
                            '/results',
                            extra: {'dataFuture': Future.value(_toResultData(s))},
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.assignment_outlined, color: primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Sesión #$sessionNumber',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1E293B),
                                              fontSize: 16,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        date,
                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      ),
                                      if ((s['notes'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          s['notes'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                  },
                  childCount: _filtered.length,
                ),
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

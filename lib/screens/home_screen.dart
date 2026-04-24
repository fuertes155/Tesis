import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../providers/data_providers.dart';
import '../models/session.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/status_chart.dart';
import '../widgets/home_header.dart';
import '../widgets/activity_filters.dart';
import '../widgets/home_kpi_section.dart';
import '../widgets/home_dashboard_grid.dart';
import '../widgets/home_recent_activity_section.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_decorations.dart';
import '../providers/api_providers.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  ApiService? _api;
  bool _loading = true;
  int _patientsCount = 0;
  int _sessionsToday = 0;
  int _sessionsPending = 0;
  List<Session> _recentSessions = [];
  Map<int, String> _patientNames = {};
  List<int> _weeklyCounts = const [0, 0, 0, 0, 0, 0, 0];
  List<int> _counts14 = const [];
  List<int> _pendingCounts14 = const [];
  List<int> _counts30 = const [];
  List<Session> _allSessions = [];
  int _daysFilter = 7;
  String _statusFilter = 'all';
  String _searchQuery = '';
  String _sortMode = 'date_desc';
  int _todayVsYesterdayPct = 0;
  int _pendingWeekDeltaPct = 0;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    final api = await ref.read(apiServiceProvider.future);
    if (!mounted) return;
    setState(() => _api = api);
    
    final savedDays = api.homeDaysFilter;
    final savedStatus = api.homeStatusFilter;
    final savedQuery = api.homeSearchQuery;
    final savedSort = api.homeSortMode;
    if (savedDays != null) _daysFilter = savedDays;
    if (savedStatus != null) _statusFilter = savedStatus;
    if (savedQuery != null) _searchQuery = savedQuery;
    if (savedSort != null) _sortMode = savedSort;
    await _loadPrefs();
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final pList = await ref.read(patientsProvider.future);
      final sList = await ref.read(sessionsProvider.future);

      final names = <int, String>{};
      for (final p in pList) {
        names[p.id] = p.name;
      }
      final today = DateTime.now();
      int pendingCount = 0;
      // buckets últimos 30 y 14 días
      final buckets30 = List.generate(30, (i) {
        final d = DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: 29 - i));
        return DateTime(d.year, d.month, d.day);
      });
      final counts30 = List<int>.filled(30, 0);
      // buckets últimos 14 días para comparar semana actual vs anterior
      final buckets14 = List.generate(14, (i) {
        final d = DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: 13 - i));
        return DateTime(d.year, d.month, d.day);
      });
      final counts14 = List<int>.filled(14, 0);
      final pending14 = List<int>.filled(14, 0);
      for (final s in sList) {
        final status = s.status.toLowerCase();
        final d = s.date;
        if (true) { // d is already DateTime
          final dd = DateTime(d.year, d.month, d.day);
          for (var i = 0; i < buckets30.length; i++) {
            if (dd == buckets30[i]) {
              counts30[i] += 1;
              break;
            }
          }
          for (var i = 0; i < buckets14.length; i++) {
            if (dd == buckets14[i]) {
              counts14[i] += 1;
              if (status.isEmpty ||
                  status == 'scheduled' ||
                  status == 'en_progreso') {
                pending14[i] += 1;
              }
              break;
            }
          }
        }
        if (status.isEmpty ||
            status == 'scheduled' ||
            status == 'en_progreso') {
          pendingCount += 1;
        }
      }
      final counts = counts14.sublist(7); // últimos 7 para el gráfico
      final todayCount = counts14.isNotEmpty ? counts14.last : 0;
      final yesterdayCount = counts14.length >= 2
          ? counts14[counts14.length - 2]
          : 0;
      final thisWeekPending = pending14
          .sublist(7)
          .fold<int>(0, (a, b) => a + b);
      final prevWeekPending = pending14
          .sublist(0, 7)
          .fold<int>(0, (a, b) => a + b);
      int pctChange(int cur, int prev) {
        if (prev == 0) return cur == 0 ? 0 : 100;
        return (((cur - prev) / prev) * 100).round();
      }

      final todayPct = pctChange(todayCount, yesterdayCount);
      final pendingPct = pctChange(thisWeekPending, prevWeekPending);

      final sortedSessions = List<Session>.from(sList);
      sortedSessions.sort((a, b) {
        return b.date.compareTo(a.date);
      });

      setState(() {
        _patientsCount = pList.length;
        _sessionsToday = todayCount;
        _sessionsPending = pendingCount;
        _recentSessions = sortedSessions.take(5).toList();
        _patientNames = names;
        _weeklyCounts = counts;
        _counts14 = counts14;
        _pendingCounts14 = pending14;
        _counts30 = counts30;
        _todayVsYesterdayPct = todayPct;
        _pendingWeekDeltaPct = pendingPct;
        _allSessions = sortedSessions;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: context.sem.danger,
          ),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getInt('home_days');
    final s = prefs.getString('home_status');
    final q = prefs.getString('home_search');
    final o = prefs.getString('home_sort');
    if (!mounted) return;
    setState(() {
      if (d != null) _daysFilter = d;
      if (s != null) _statusFilter = s;
      if (q != null) _searchQuery = q;
      if (o != null) _sortMode = o;
    });
    if (_api == null) return;
    _api!.setHomeFilters(days: _daysFilter, status: _statusFilter);
    _api!.setHomeSearchAndSort(query: _searchQuery, sortMode: _sortMode);
  }

  Future<void> _persistFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_days', _daysFilter);
    await prefs.setString('home_status', _statusFilter);
    await prefs.setString('home_search', _searchQuery);
    await prefs.setString('home_sort', _sortMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;
    final r = context.radii;
    assert(_touchState() >= 0);

    return Scaffold(
      backgroundColor: cs.surface,
      body: AppDecorations.meshBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: spacing.lg, bottom: spacing.lg - 4),
              title: const HomeHeader(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/profile');
                },
                tooltip: 'Mi Perfil',
              ),
              if (_api?.currentRole != 'user')
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _fetch();
                  },
                  tooltip: 'Actualizar',
                ),
              IconButton(
                icon: Icon(
                  Icons.logout_rounded,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/');
                },
                tooltip: 'Cerrar Sesión',
              ),
              SizedBox(width: spacing.md),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.xl),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saludo dinámico
                      Builder(builder: (context) {
                        final hour = DateTime.now().hour;
                        final greeting = hour < 12
                            ? 'Buenos días'
                            : hour < 18
                                ? 'Buenas tardes'
                                : 'Buenas noches';
                        final now = DateTime.now();
                        final months = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
                        final dateStr = '${now.day} de ${months[now.month - 1]}, ${now.year}';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$greeting, ',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: cs.onSurfaceVariant,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final profile = ref.watch(currentUserProvider);
                                    return profile.when(
                                      data: (u) => Text(
                                        u.username,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: cs.onSurface,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      loading: () => Text(
                                        '---',
                                        style: theme.textTheme.headlineMedium,
                                      ),
                                      error: (_, __) => Text(
                                        _api?.currentUsername ?? 'Doctor',
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: cs.onSurface,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  ' 👋',
                                  style: theme.textTheme.headlineMedium,
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.xs),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 14, color: cs.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  dateStr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }).animate().fadeIn().slideX(begin: -0.08),
                      SizedBox(height: spacing.xl),
                      HomeKpiSection(
                        loading: _loading,
                        patientsCount: _patientsCount,
                        sessionsToday: _sessionsToday,
                        sessionsPending: _sessionsPending,
                        todayVsYesterdayPct: _todayVsYesterdayPct,
                        pendingWeekDeltaPct: _pendingWeekDeltaPct,
                        counts30: _counts30,
                      ),
                      SizedBox(height: spacing.xl),
                      Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 20,
                            color: cs.primary,
                          ),
                          SizedBox(width: spacing.sm),
                          Text(
                            'ACCESO RÁPIDO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                      SizedBox(height: spacing.lg),
                      const HomeDashboardGrid(),
                      const SizedBox(height: 64),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 20,
                                color: cs.primary,
                              ),
                              SizedBox(width: spacing.sm),
                              Text(
                                'ANÁLISIS DE ACTIVIDAD',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          if (!_loading)
                            ActivityFilters(
                              daysFilter: _daysFilter,
                              statusFilter: _statusFilter,
                              searchQuery: _searchQuery,
                              sortMode: _sortMode,
                              onDaysChanged: (v) {
                                setState(() => _daysFilter = v);
                                _api?.setHomeFilters(
                                  days: _daysFilter,
                                  status: _statusFilter,
                                );
                                _persistFilters();
                              },
                              onStatusChanged: (v) {
                                setState(() => _statusFilter = v);
                                _api?.setHomeFilters(
                                  days: _daysFilter,
                                  status: _statusFilter,
                                );
                                _persistFilters();
                              },
                              onSearchChanged: (v) {
                                setState(() => _searchQuery = v);
                                _api?.setHomeSearchAndSort(
                                  query: _searchQuery,
                                  sortMode: _sortMode,
                                );
                                _persistFilters();
                              },
                              onSortSelected: (v) {
                                setState(() => _sortMode = v);
                                _api?.setHomeSearchAndSort(
                                  query: _searchQuery,
                                  sortMode: _sortMode,
                                );
                                _persistFilters();
                              },
                            ),
                        ],
                      ).animate().fadeIn(delay: 300.ms),
                      SizedBox(height: spacing.xl),
                      if (_loading)
                        const WeeklyChartSkeleton().animate().fadeIn(
                          duration: 220.ms,
                        )
                      else
                        Builder(builder: (ctx) {
                            final glass = ctx.glass;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Container(
                                    padding: EdgeInsets.all(spacing.lg),
                                    decoration: BoxDecoration(
                                      gradient: glass.cardGradient,
                                      borderRadius: r.radiusXl,
                                      border: Border.all(color: glass.borderColor, width: 1),
                                      boxShadow: ctx.premiumShadows,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: cs.primary.withValues(alpha: 0.10),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.bar_chart_rounded, color: cs.primary, size: 16),
                                            ),
                                            SizedBox(width: spacing.sm),
                                            Text(
                                              'Sesiones por Día',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing.xl),
                                        WeeklyChart(counts: _weeklyCounts),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing.lg),
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    padding: EdgeInsets.all(spacing.lg),
                                    decoration: BoxDecoration(
                                      gradient: glass.cardGradient,
                                      borderRadius: r.radiusXl,
                                      border: Border.all(color: glass.borderColor, width: 1),
                                      boxShadow: ctx.premiumShadows,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: cs.tertiary.withValues(alpha: 0.10),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.donut_small_rounded, color: cs.tertiary, size: 16),
                                            ),
                                            SizedBox(width: spacing.sm),
                                            Text(
                                              'Estado',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing.xl),
                                        StatusChart(
                                          completed: _statusCounts(_daysFilter)['completed'] ?? 0,
                                          pending: _statusCounts(_daysFilter)['pending'] ?? 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 64),
                      Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: cs.primary,
                          ),
                          SizedBox(width: spacing.sm),
                          Text(
                            'REGISTRO DE ACTIVIDAD',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms),
                      SizedBox(height: spacing.lg),
                      HomeRecentActivitySection(
                        loading: _loading,
                        sessions: _filteredRecent(),
                        patientNames: _patientNames,
                        onTapSession: (s) async {
                          final pid = s.patientId;
                          final name = _patientNames[pid] ?? 'Paciente #$pid';
                          final result = await context.push(
                            '/patient_detail',
                            extra: {'name': name, 'id': pid},
                          );
                          if (result == true) await _fetch();
                        },
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

extension _HomeScreenStateInternals on HomeScreenState {
  int _touchState() {
    return _recentSessions.length + _counts14.length + _pendingCounts14.length;
  }
}

extension on HomeScreenState {
  List<Session> _filteredRecent() {
    final now = DateTime.now();
    final since = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: _daysFilter - 1));
    var list = _allSessions.where((s) {
      final d = s.date;
      return d.isAfter(since) || d.isAtSameMomentAs(since);
    }).toList();

    if (_statusFilter != 'all') {
      list = list
          .where((s) => s.status.toLowerCase() == _statusFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        final pid = s.patientId;
        final name = _patientNames[pid]?.toLowerCase() ?? '';
        return name.contains(q) || pid.toString().contains(q);
      }).toList();
    }

    if (_sortMode == 'date_desc') {
      list.sort((a, b) => b.date.compareTo(a.date));
    } else if (_sortMode == 'date_asc') {
      list.sort((a, b) => a.date.compareTo(b.date));
    }

    return list.take(5).toList();
  }

  Map<String, int> _statusCounts(int days) {
    return _statusCountsHelper(_allSessions, days);
  }
}

Map<String, int> _statusCountsHelper(List<Session> sessions, int days) {
  final now = DateTime.now();
  final since = now.subtract(Duration(days: days - 1));
  int completed = 0;
  int pending = 0;
  for (final s in sessions) {
    final status = s.status.toLowerCase();
    final d = s.date;
    if (d.isBefore(DateTime(since.year, since.month, since.day))) continue;
    if (status == 'completed' || status == 'completada') {
      completed += 1;
    } else {
      pending += 1;
    }
  }
  return {'completed': completed, 'pending': pending};
}

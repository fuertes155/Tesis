import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/status_chart.dart';
import '../widgets/home_header.dart';
import '../widgets/activity_filters.dart';
import '../widgets/home_kpi_section.dart';
import '../widgets/home_dashboard_grid.dart';
import '../widgets/home_recent_activity_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  bool _loading = true;
  int _patientsCount = 0;
  int _sessionsToday = 0;
  int _sessionsPending = 0;
  List<Map<String, dynamic>> _recentSessions = [];
  Map<int, String> _patientNames = {};
  List<int> _weeklyCounts = const [0, 0, 0, 0, 0, 0, 0];
  List<int> _counts14 = const [];
  List<int> _pendingCounts14 = const [];
  List<int> _counts30 = const [];
  List<Map<String, dynamic>> _allSessions = [];
  int _daysFilter = 7;
  String _statusFilter = 'all';
  String _searchQuery = '';
  String _sortMode = 'date_desc';
  int _todayVsYesterdayPct = 0;
  int _pendingWeekDeltaPct = 0;

  @override
  void initState() {
    super.initState();
    final savedDays = _api.homeDaysFilter;
    final savedStatus = _api.homeStatusFilter;
    final savedQuery = _api.homeSearchQuery;
    final savedSort = _api.homeSortMode;
    if (savedDays != null) _daysFilter = savedDays;
    if (savedStatus != null) _statusFilter = savedStatus;
    if (savedQuery != null) _searchQuery = savedQuery;
    if (savedSort != null) _sortMode = savedSort;
    _loadPrefs().then((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final patients = await _api.getPatients();
      final sessions = await _api.getSessions();
      final pList = patients.cast<Map<String, dynamic>>();
      final sList = sessions.cast<Map<String, dynamic>>();
      final names = <int, String>{};
      for (final p in pList) {
        final id = p['id'];
        final name = p['name']?.toString() ?? '';
        if (id is int && name.isNotEmpty) names[id] = name;
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
        final status = (s['status'] ?? '').toString().toLowerCase();
        final dateStr = s['date']?.toString();
        DateTime? d;
        if (dateStr != null) d = DateTime.tryParse(dateStr);
        if (d != null) {
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
      sList.sort((a, b) {
        final ad = a['date']?.toString() ?? '';
        final bd = b['date']?.toString() ?? '';
        return bd.compareTo(ad);
      });
      setState(() {
        _patientsCount = pList.length;
        _sessionsToday = todayCount;
        _sessionsPending = pendingCount;
        _recentSessions = sList.take(5).cast<Map<String, dynamic>>().toList();
        _patientNames = names;
        _weeklyCounts = counts;
        _counts14 = counts14;
        _pendingCounts14 = pending14;
        _counts30 = counts30;
        _todayVsYesterdayPct = todayPct;
        _pendingWeekDeltaPct = pendingPct;
        _allSessions = sList;
        _loading = false;
      });
    } catch (_) {
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
    _api.setHomeFilters(days: _daysFilter, status: _statusFilter);
    _api.setHomeSearchAndSort(query: _searchQuery, sortMode: _sortMode);
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
    assert(_touchState() >= 0);

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
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
              title: const HomeHeader(),
            ),
            actions: [
              if (_api.currentRole != 'user')
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: _fetch,
                  tooltip: 'Actualizar',
                ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF64748B),
                ),
                onPressed: () => context.go('/'),
                tooltip: 'Cerrar Sesión',
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    'Hola, ${_api.currentUsername ?? 'Doctor'}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.1),
                  const SizedBox(height: 8),
                  Text(
                    'Bienvenido de nuevo al panel de gestión.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                  const SizedBox(height: 48),
                  HomeKpiSection(
                    loading: _loading,
                    patientsCount: _patientsCount,
                    sessionsToday: _sessionsToday,
                    sessionsPending: _sessionsPending,
                    todayVsYesterdayPct: _todayVsYesterdayPct,
                    pendingWeekDeltaPct: _pendingWeekDeltaPct,
                    counts30: _counts30,
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        size: 20,
                        color: Color(0xFF1A237E),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ACCESO RÁPIDO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  const HomeDashboardGrid(),
                  const SizedBox(height: 64),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.analytics_outlined,
                            size: 20,
                            color: Color(0xFF1A237E),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'ANÁLISIS DE ACTIVIDAD',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF64748B),
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
                            _api.setHomeFilters(
                              days: _daysFilter,
                              status: _statusFilter,
                            );
                            _persistFilters();
                          },
                          onStatusChanged: (v) {
                            setState(() => _statusFilter = v);
                            _api.setHomeFilters(
                              days: _daysFilter,
                              status: _statusFilter,
                            );
                            _persistFilters();
                          },
                          onSearchChanged: (v) {
                            setState(() => _searchQuery = v);
                            _api.setHomeSearchAndSort(
                              query: _searchQuery,
                              sortMode: _sortMode,
                            );
                            _persistFilters();
                          },
                          onSortSelected: (v) {
                            setState(() => _sortMode = v);
                            _api.setHomeSearchAndSort(
                              query: _searchQuery,
                              sortMode: _sortMode,
                            );
                            _persistFilters();
                          },
                        ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 32),
                  if (_loading)
                    const WeeklyChartSkeleton().animate().fadeIn(
                      duration: 220.ms,
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sesiones por Día',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                WeeklyChart(counts: _weeklyCounts),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Distribución de Estado',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                StatusChart(
                                  completed:
                                      _statusCounts(_daysFilter)['completed'] ??
                                      0,
                                  pending:
                                      _statusCounts(_daysFilter)['pending'] ??
                                      0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 64),
                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: Color(0xFF1A237E),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'REGISTRO DE ACTIVIDAD',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                  HomeRecentActivitySection(
                    loading: _loading,
                    sessions: _filteredRecent(),
                    patientNames: _patientNames,
                    onTapSession: (s) async {
                      final pid = s['patient_id'];
                      final name = pid is int
                          ? (_patientNames[pid] ?? 'Paciente #$pid')
                          : 'Sesión';
                      if (pid is int) {
                        final result = await context.push(
                          '/patient_detail',
                          extra: {'name': name, 'id': pid},
                        );
                        if (result == true) await _fetch();
                      } else {
                        context.push('/history');
                      }
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
    );
  }
}

extension _HomeScreenStateInternals on HomeScreenState {
  int _touchState() {
    return _recentSessions.length + _counts14.length + _pendingCounts14.length;
  }
}

extension on HomeScreenState {
  List<Map<String, dynamic>> _filteredRecent() {
    final now = DateTime.now();
    final since = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: _daysFilter - 1));
    var list = _allSessions.where((s) {
      final dateStr = s['date']?.toString();
      DateTime? d;
      if (dateStr != null) d = DateTime.tryParse(dateStr);
      if (d == null) return false;
      final dd = DateTime(d.year, d.month, d.day);
      if (dd.isBefore(since)) return false;
      final st = (s['status'] ?? '').toString().toLowerCase();
      if (_statusFilter == 'completed') {
        return st == 'completed' || st == 'completada';
      }
      if (_statusFilter == 'pending') {
        return !(st == 'completed' || st == 'completada');
      }
      return true;
    }).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final pid = s['patient_id'];
        final name = pid is int ? (_patientNames[pid] ?? 'Paciente #$pid') : '';
        final notes = (s['notes'] ?? '').toString();
        return name.toLowerCase().contains(q) ||
            notes.toLowerCase().contains(q);
      }).toList();
    }
    int byDateDesc(a, b) {
      final ad = a['date']?.toString() ?? '';
      final bd = b['date']?.toString() ?? '';
      return bd.compareTo(ad);
    }

    int byDateAsc(a, b) => -byDateDesc(a, b);
    int byStatus(a, b) {
      final as = (a['status'] ?? '').toString();
      final bs = (b['status'] ?? '').toString();
      final c = as.compareTo(bs);
      if (c != 0) return c;
      return byDateDesc(a, b);
    }

    int byPatient(a, b) {
      final ap = a['patient_id'];
      final bp = b['patient_id'];
      final an = ap is int ? (_patientNames[ap] ?? 'Paciente #$ap') : '';
      final bn = bp is int ? (_patientNames[bp] ?? 'Paciente #$bp') : '';
      final c = an.compareTo(bn);
      if (c != 0) return c;
      return byDateDesc(a, b);
    }

    switch (_sortMode) {
      case 'date_asc':
        list.sort(byDateAsc);
        break;
      case 'status':
        list.sort(byStatus);
        break;
      case 'patient':
        list.sort(byPatient);
        break;
      case 'date_desc':
      default:
        list.sort(byDateDesc);
    }
    return list.take(5).cast<Map<String, dynamic>>().toList();
  }

  Map<String, int> _statusCounts(int days) {
    return _statusCountsHelper(_allSessions, days);
  }
}

Map<String, int> _statusCountsHelper(
  List<Map<String, dynamic>> sessions,
  int days,
) {
  final now = DateTime.now();
  final since = now.subtract(Duration(days: days - 1));
  int completed = 0;
  int pending = 0;
  for (final s in sessions) {
    final dateStr = s['date']?.toString();
    final status = (s['status'] ?? '').toString().toLowerCase();
    DateTime? d;
    if (dateStr != null) {
      d = DateTime.tryParse(dateStr);
    }
    if (d == null) continue;
    if (d.isBefore(DateTime(since.year, since.month, since.day))) continue;
    if (status == 'completed' || status == 'completada') {
      completed += 1;
    } else {
      pending += 1;
    }
  }
  return {'completed': completed, 'pending': pending};
}

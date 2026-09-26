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
import '../widgets/home_hero_banner.dart';
import '../widgets/dashboard_panel.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_decorations.dart';
import '../providers/api_providers.dart';

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
    if (!mounted) return;
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
        // Ensure s.date is handled as DateTime
        final d = s.date;
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

      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: context.sem.danger,
        ),
      );
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
    final cs = Theme.of(context).colorScheme;
    assert(_touchState() >= 0);
    final role = _api?.currentRole;

    return Scaffold(
      backgroundColor: cs.surface,
      body: AppDecorations.meshBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Contenido centrado con ancho máximo en pantallas grandes.
            final margen = constraints.maxWidth > 1328
                ? (constraints.maxWidth - 1280) / 2
                : (constraints.maxWidth < 600 ? 16.0 : 24.0);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 72,
                  titleSpacing: margen,
                  backgroundColor: cs.surface.withValues(alpha: 0.92),
                  surfaceTintColor: Colors.transparent,
                  shape: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7))),
                  title: const HomeHeader(),
                  actions: [
                    if (role != 'user')
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _fetch();
                        },
                        tooltip: 'Actualizar',
                      ),
                    const SizedBox(width: 4),
                    _MenuUsuario(fallbackName: _api?.currentUsername ?? 'Usuario'),
                    SizedBox(width: margen),
                  ],
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(margen, 24, margen, 48),
                  sliver: SliverToBoxAdapter(child: _contenido(context, role)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, String? role) {
    final cs = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 24);

    final semanal = DashboardPanel(
      icon: Icons.bar_chart_rounded,
      title: 'Actividad semanal',
      subtitle: 'Sesiones registradas por día',
      trailing: _loading
          ? null
          : _ChipTotal(total: _weeklyCounts.fold<int>(0, (a, b) => a + b)),
      child: _loading ? const WeeklyChartSkeleton() : WeeklyChart(counts: _weeklyCounts),
    );

    final estado = DashboardPanel(
      icon: Icons.donut_large_rounded,
      iconColor: cs.secondary,
      title: 'Estado de sesiones',
      subtitle: 'Últimos $_daysFilter días',
      child: _loading
          ? const StatusChartSkeleton()
          : StatusChart(
              completed: _statusCounts(_daysFilter)['completed'] ?? 0,
              pending: _statusCounts(_daysFilter)['pending'] ?? 0,
            ),
    );

    final accesos = DashboardPanel(
      icon: Icons.bolt_rounded,
      iconColor: cs.tertiary,
      title: 'Accesos rápidos',
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: const HomeDashboardGrid(),
    );

    final actividad = DashboardPanel(
      icon: Icons.history_rounded,
      title: 'Actividad reciente',
      subtitle: 'Últimas sesiones de tus pacientes',
      trailingBreakpoint: 900,
      trailing: _loading
          ? null
          : ActivityFilters(
              daysFilter: _daysFilter,
              statusFilter: _statusFilter,
              searchQuery: _searchQuery,
              sortMode: _sortMode,
              onDaysChanged: (v) {
                setState(() => _daysFilter = v);
                _api?.setHomeFilters(days: _daysFilter, status: _statusFilter);
                _persistFilters();
              },
              onStatusChanged: (v) {
                setState(() => _statusFilter = v);
                _api?.setHomeFilters(days: _daysFilter, status: _statusFilter);
                _persistFilters();
              },
              onSearchChanged: (v) {
                setState(() => _searchQuery = v);
                _api?.setHomeSearchAndSort(query: _searchQuery, sortMode: _sortMode);
                _persistFilters();
              },
              onSortSelected: (v) {
                setState(() => _sortMode = v);
                _api?.setHomeSearchAndSort(query: _searchQuery, sortMode: _sortMode);
                _persistFilters();
              },
            ),
      child: _allSessions.isEmpty && !_loading
          ? _SinSesiones(
              mostrarAccion: role != 'user',
              onNuevaSesion: () => context.push('/new_session'),
            )
          : HomeRecentActivitySection(
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
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHeroBanner(
          loading: _loading,
          sessionsToday: _sessionsToday,
          sessionsPending: _sessionsPending,
          role: role,
          fallbackName: _api?.currentUsername ?? 'Doctor',
          onNewSession: () => context.push('/new_session'),
          onPatients: () => context.push('/patients'),
          onResults: () => context.push('/history'),
        ).animate().fadeIn(duration: 300.ms).moveY(begin: 10, end: 0),
        gap,
        HomeKpiSection(
          loading: _loading,
          patientsCount: _patientsCount,
          sessionsToday: _sessionsToday,
          sessionsPending: _sessionsPending,
          todayVsYesterdayPct: _todayVsYesterdayPct,
          pendingWeekDeltaPct: _pendingWeekDeltaPct,
          counts30: _counts30,
          weeklyCounts: _weeklyCounts,
        ),
        gap,
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1040) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: [semanal, gap, actividad])),
                  const SizedBox(width: 24),
                  SizedBox(width: 360, child: Column(children: [accesos, gap, estado])),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [accesos, gap, semanal, gap, estado, gap, actividad],
            );
          },
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
      ],
    );
  }
}

/// Avatar con menú: perfil y cierre de sesión.
class _MenuUsuario extends ConsumerWidget {
  const _MenuUsuario({required this.fallbackName});

  final String fallbackName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final usuario = ref.watch(currentUserProvider).valueOrNull;
    final nombre = (usuario?.fullName?.trim().isNotEmpty ?? false)
        ? usuario!.fullName!.trim()
        : (usuario?.username ?? fallbackName);
    final iniciales = nombre
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return PopupMenuButton<String>(
      tooltip: 'Cuenta',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      onSelected: (v) {
        HapticFeedback.lightImpact();
        if (v == 'perfil') context.push('/profile');
        if (v == 'salir') context.go('/');
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre, style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface)),
              if (usuario != null) Text(usuario.username, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'perfil',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline_rounded),
            title: Text('Mi perfil'),
          ),
        ),
        PopupMenuItem(
          value: 'salir',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded, color: cs.error),
            title: Text('Cerrar sesión', style: TextStyle(color: cs.error)),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              child: Text(
                iniciales.isEmpty ? '?' : iniciales,
                style: theme.textTheme.labelMedium?.copyWith(color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more_rounded, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ChipTotal extends StatelessWidget {
  const _ChipTotal({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$total en total',
        style: theme.textTheme.labelMedium?.copyWith(color: cs.primary),
      ),
    );
  }
}

/// Estado vacío cuando todavía no hay ninguna sesión registrada.
class _SinSesiones extends StatelessWidget {
  const _SinSesiones({required this.mostrarAccion, required this.onNuevaSesion});

  final bool mostrarAccion;
  final VoidCallback onNuevaSesion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_note_rounded, size: 30, color: cs.primary),
          ),
          const SizedBox(height: 14),
          Text('Aún no hay sesiones registradas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Las evaluaciones aparecerán aquí cuando empieces a trabajar con tus pacientes.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          if (mostrarAccion) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onNuevaSesion,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Iniciar primera sesión'),
            ),
          ],
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import 'game_results.dart';

class GameFlowScreen extends StatefulWidget {
  final List<String> gameRoutes;

  const GameFlowScreen({super.key, required this.gameRoutes});

  @override
  State<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends State<GameFlowScreen> {
  bool _running = false;
  String? _error;
  int? _age;
  Map<String, dynamic>? _lastResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_running) return;
    _running = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final routes = widget.gameRoutes;
    if (routes.isEmpty) {
      if (!mounted) return;
      context.go('/home');
      return;
    }

    try {
      final api = ApiService();
      final pid = api.currentPatientId;
      final patient = await api.getPatient(pid);
      final a = patient['age'];
      _age = a is int ? a : int.tryParse('$a');
    } catch (e) {
      _error = 'No se pudo cargar la edad del paciente';
    }

    for (int i = 0; i < routes.length; i++) {
      if (!mounted) return;
      final result = await context.push<Object?>(
        routes[i],
        extra: {
          'flow': true,
          'index': i,
          'total': routes.length,
          if (_age != null) 'age': _age,
        },
      );

      if (!mounted) return;
      if (result is Map<String, dynamic>) {
        final aborted = result['aborted'] == true;
        if (aborted) {
          context.go('/home');
          return;
        }
        final r = result['result'];
        if (r is Map) {
          _lastResult = r.cast<String, dynamic>();
        }
      }
    }

    if (!mounted) return;
    if (_lastResult != null) {
      GameResults.navigateToResults(
        context,
        title: _lastResult?['title']?.toString() ?? 'Resultados',
        score: (_lastResult?['score'] as num?)?.toInt() ?? 70,
        details:
            (_lastResult?['details'] as Map?)?.cast<String, dynamic>() ??
            const {},
      );
      return;
    }
    GameResults.navigateToResultsFromApi(
      context,
      patientId: ApiService().currentPatientId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.gameRoutes.length == 1
        ? 'Iniciando prueba...'
        : 'Iniciando protocolo (${widget.gameRoutes.length} pruebas)...';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Evaluación Cognitiva',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Salir'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

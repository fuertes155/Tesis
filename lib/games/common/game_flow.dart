import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import 'game_results.dart';

class GameFlow extends StatefulWidget {
  final List<String> gameRoutes;

  const GameFlow({super.key, required this.gameRoutes});

  @override
  State<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<GameFlow> {
  int _currentIndex = 0;
  int? _age;

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
    _startNext();
  }

  Future<void> _loadPatientInfo() async {
    try {
      final api = GetIt.I<ApiService>();
      final pid = api.currentPatientId;
      final patient = await api.getPatient(pid);
      _age = patient.age;
    } catch (e) {
      _age = 30;
    }
    if (mounted) setState(() {});
  }

  void _startNext() {
    if (_currentIndex >= widget.gameRoutes.length) {
      _complete();
      return;
    }

    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final route = widget.gameRoutes[_currentIndex];
      _currentIndex++;
      context.push(route).then((_) => _startNext());
    });
  }

  Future<void> _complete() async {
    await GameResults.sendSession(
      status: 'completed',
      notes: 'Batería de pruebas finalizada.',
    );
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.gameRoutes.length == 1
        ? 'Iniciando prueba...'
        : 'Iniciando protocolo (${widget.gameRoutes.length} pruebas)...';
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Evaluación Cognitiva'),
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
                  ),
                ),
                if (_age != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Paciente: $_age años',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
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

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'common/game_results.dart';
import 'common/game_intro.dart';
import 'common/game_scoring.dart';
import '../widgets/animated_dialog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';

class VisualMemoryGame extends ConsumerStatefulWidget {
  final bool flowMode;
  final int? flowIndex;
  final int? flowTotal;
  final int? patientAge;

  const VisualMemoryGame({
    super.key,
    this.flowMode = false,
    this.flowIndex,
    this.flowTotal,
    this.patientAge,
  });

  @override
  ConsumerState<VisualMemoryGame> createState() => _VisualMemoryGameState();
}

class _VisualMemoryGameState extends ConsumerState<VisualMemoryGame> {
  static const int gridSize = 4;
  static const int totalCells = gridSize * gridSize;

  List<int> _targetIndices = [];
  final Set<int> _selectedIndices = {};
  bool _showingPattern = false;
  bool _isGameOver = false;
  int _score = 0;
  int _level = 1;
  int _itemsToRemember = 3;
  int _memorizeSeconds = 2;
  int _countdown = 0;
  Timer? _countdownTimer;
  int? _wrongIndex;
  bool _started = false;
  DateTime? _selectionStart;
  final List<int> _selectionTimesMs = [];
  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _started = true;
      _gameStartTime = DateTime.now();
      _isGameOver = false;
      _score = 0;
      _level = 1;
      _itemsToRemember = 3;
      _memorizeSeconds = 2;
      _selectionStart = null;
      _selectionTimesMs.clear();
      _startLevel();
    });
  }

  void _startLevel() {
    setState(() {
      _selectedIndices.clear();
      _generateTargets();
      _showingPattern = true;
      _countdown = _memorizeSeconds;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
      }
      setState(() {
        _countdown = (_countdown - 1).clamp(0, _memorizeSeconds);
      });
    });

    // Hide pattern after memorizeSeconds
    Timer(Duration(seconds: _memorizeSeconds), () {
      if (mounted) {
        setState(() {
          _showingPattern = false;
          _selectionStart = DateTime.now();
        });
      }
    });
  }

  void _generateTargets() {
    final random = Random();
    _targetIndices = [];
    while (_targetIndices.length < _itemsToRemember) {
      int index = random.nextInt(totalCells);
      if (!_targetIndices.contains(index)) {
        _targetIndices.add(index);
      }
    }
  }

  void _onCellTap(int index) {
    if (_showingPattern || _isGameOver || _selectedIndices.contains(index)) {
      return;
    }

    setState(() {
      _selectedIndices.add(index);
    });

    if (_targetIndices.contains(index)) {
      HapticFeedback.mediumImpact();
      // Correct selection
      if (_selectedIndices.where((i) => _targetIndices.contains(i)).length ==
          _targetIndices.length) {
        final start = _selectionStart;
        if (start != null) {
          _selectionTimesMs.add(
            DateTime.now().difference(start).inMilliseconds,
          );
        }
        // Level complete
        _score += 100 * _level + (10 * _itemsToRemember);
        _level++;
        // Increase difficulty
        _itemsToRemember = (_itemsToRemember + 1).clamp(3, totalCells ~/ 2);
        _memorizeSeconds = (_memorizeSeconds - 1).clamp(1, 3);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Nivel $_level! Puntos: $_score'),
            duration: const Duration(milliseconds: 500),
          ),
        );
        Timer(const Duration(seconds: 1), _startLevel);
      }
    } else {
      // Wrong selection - Game Over
      HapticFeedback.vibrate();
      setState(() {
        _wrongIndex = index;
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        final start = _selectionStart;
        if (start != null) {
          _selectionTimesMs.add(
            DateTime.now().difference(start).inMilliseconds,
          );
        }
        setState(() {
          _wrongIndex = null;
          _isGameOver = true;
        });
        _showGameOverDialog();
      });
    }
  }

  void _showGameOverDialog() {
    final score = GameScoring.memoryScore(
      level: _level,
      rawScore: _score,
      age: widget.patientAge,
    );
    final details = <String, dynamic>{
      'Memoria': score,
      'Atención': (score - 6).clamp(20, 100),
    };
    final avgSelection = _selectionTimesMs.isEmpty
        ? 0
        : _selectionTimesMs.reduce((a, b) => a + b) ~/ _selectionTimesMs.length;
    final metrics = <String, dynamic>{
      'raw_score': _score,
      'level': _level,
      'items_to_remember': _itemsToRemember,
      'memorize_seconds': _memorizeSeconds,
      'avg_selection_ms': avgSelection,
      'selections': _selectionTimesMs.length,
    };
    final api = ref.read(apiServiceProvider).value!;
    final durationMs = _gameStartTime != null
        ? DateTime.now().difference(_gameStartTime!).inMilliseconds
        : 0;
    final future = GameResults.sendGameResult(
      api: api,
      title: 'Resultados - Memoria Visual',
      score: score,
      details: details,
      gameKey: 'visual_memory',
      metrics: metrics,
      durationMs: durationMs,
      age: widget.patientAge,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedDialog(
        child: AlertDialog(
          title: const Text('Prueba Finalizada'),
          content: Text('Puntuación final: $_score\nNivel alcanzado: $_level'),
          actions: [
            if (!widget.flowMode)
              TextButton(
                onPressed: () {
                  context.pop();
                  GameResults.navigateToResults(
                    context,
                    title: 'Resultados - Memoria Visual',
                    score: score,
                    details: details,
                  );
                },
                child: const Text('Ver Resultados'),
              ),
            if (widget.flowMode)
              TextButton(
                onPressed: () async {
                  await future;
                  if (!context.mounted) return;
                  context.pop();
                  context.pop({
                    'completed': true,
                    'result': {
                      'title': 'Resultados - Memoria Visual',
                      'nombre_prueba': 'Memoria Visual',
                      'score': score,
                      'details': details,
                      'duration_ms': durationMs,
                    },
                  });
                },
                child: Text(
                  widget.flowIndex != null &&
                          widget.flowTotal != null &&
                          widget.flowIndex! < (widget.flowTotal! - 1)
                      ? 'Siguiente'
                      : 'Finalizar',
                ),
              ),
            TextButton(
              onPressed: () {
                context.pop();
                setState(() => _started = false);
                _startGame();
              },
              child: const Text('Intentar de Nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final flowLabel =
        widget.flowMode && widget.flowIndex != null && widget.flowTotal != null
        ? 'Memoria Visual (${widget.flowIndex! + 1}/${widget.flowTotal})'
        : 'Memoria Visual';

    if (!_started) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: Text(
            flowLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          centerTitle: false,
        ),
        body: GameIntro(
          title: 'Memoria Visual',
          subtitle:
              'Evalúa tu capacidad de recordar y reconocer patrones visuales.',
          icon: Icons.grid_4x4_rounded,
          steps: const [
            'Observa el patrón de casillas AZULES durante unos segundos.',
            'Cuando el patrón desaparezca, selecciona las casillas correctas.',
            'Si te equivocas, la prueba termina.',
            'Cada nivel aumenta la dificultad.',
          ],
          actionLabel: 'Comenzar',
          onStart: _startGame,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.flowMode &&
                  widget.flowIndex != null &&
                  widget.flowTotal != null
              ? 'Memoria Visual (${widget.flowIndex! + 1}/${widget.flowTotal})'
              : 'Memoria Visual - Nivel $_level',
        ),
        actions: [
          TextButton(onPressed: _startGame, child: const Text('Reiniciar')),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight;
          final double w = constraints.maxWidth;
          
          final double maxPossibleGrid = min(w - 32, h - 260);
          final double gridSide = maxPossibleGrid.clamp(180.0, 420.0);
          final double cellSide = (gridSide - (gridSize - 1) * 12) / gridSize;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: h > 500 ? 10 : 0),
                  Text(
                    _showingPattern
                        ? 'Memoriza las casillas azules'
                        : 'Selecciona las casillas que viste',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildInfoChip('Puntos: $_score', Colors.blue, Icons.stars_rounded),
                      _buildInfoChip('Recordar: $_itemsToRemember', Colors.orange, Icons.psychology_rounded),
                      _buildInfoChip('Tiempo: ${_memorizeSeconds}s', Colors.purple, Icons.timer_rounded),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.topCenter,
                    child: UnconstrainedBox(
                      child: SizedBox(
                        width: gridSide,
                        height: gridSide,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: cellSide,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            bool isTarget = _targetIndices.contains(index);
                            bool isSelected = _selectedIndices.contains(index);
                            bool showAsTarget = _showingPattern && isTarget;
                            Color cellColor = isSelected 
                                ? (isTarget ? Colors.green : Colors.red) 
                                : (showAsTarget ? Colors.blue : Colors.grey.shade200);
                            return _buildGridCell(index, cellColor, showAsTarget, isTarget);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(int index, Color cellColor, bool showAsTarget, bool isTarget) {
    return GestureDetector(
      onTap: () => _onCellTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (showAsTarget || _selectedIndices.contains(index))
              BoxShadow(
                color: cellColor.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: showAsTarget
            ? Center(
                child: Text(
                  _countdown > 0 ? '$_countdown' : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    ).animate(target: _wrongIndex == index ? 1 : 0).shake(
          duration: 250.ms,
          hz: 6,
          offset: const Offset(10, 0),
        );
  }
}

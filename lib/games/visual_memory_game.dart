import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'common/game_results.dart';
import '../widgets/animated_dialog.dart';

class VisualMemoryGame extends StatefulWidget {
  const VisualMemoryGame({super.key});

  @override
  State<VisualMemoryGame> createState() => _VisualMemoryGameState();
}

class _VisualMemoryGameState extends State<VisualMemoryGame> {
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

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      _isGameOver = false;
      _score = 0;
      _level = 1;
      _itemsToRemember = 3;
      _memorizeSeconds = 2;
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
      // Correct selection
      if (_selectedIndices.where((i) => _targetIndices.contains(i)).length ==
          _targetIndices.length) {
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
      setState(() {
        _wrongIndex = index;
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        setState(() {
          _wrongIndex = null;
          _isGameOver = true;
        });
        _showGameOverDialog();
      });
    }
  }

  void _showGameOverDialog() {
    GameResults.sendSession(
      patientId: 1,
      status: 'completed',
      notes:
          'visual_memory score=$_score level=$_level items=$_itemsToRemember',
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedDialog(
        child: AlertDialog(
          title: const Text('Prueba Finalizada'),
          content: Text('Puntuación final: $_score\nNivel alcanzado: $_level'),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                GameResults.navigateToResultsFromApi(context, patientId: 1);
              },
              child: const Text('Ver Resultados'),
            ),
            TextButton(
              onPressed: () {
                context.pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Memoria Visual - Nivel $_level'),
        actions: [
          TextButton(onPressed: _startGame, child: const Text('Reiniciar')),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _showingPattern
                    ? 'Memoriza las casillas azules'
                    : 'Selecciona las casillas que viste',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(label: Text('Puntos: $_score')),
                  const SizedBox(width: 12),
                  Chip(label: Text('Recordar: $_itemsToRemember')),
                  const SizedBox(width: 12),
                  Chip(label: Text('Memorizar: ${_memorizeSeconds}s')),
                ],
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    bool isTarget = _targetIndices.contains(index);
                    bool isSelected = _selectedIndices.contains(index);
                    bool showAsTarget = _showingPattern && isTarget;

                    Color cellColor = Colors.grey.shade300;
                    if (showAsTarget) {
                      cellColor = Colors.blue;
                    } else if (isSelected) {
                      cellColor = isTarget ? Colors.green : Colors.red;
                    }

                    final cell = GestureDetector(
                      onTap: () => _onCellTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: _showingPattern
                            ? Center(
                                child: Text(
                                  _countdown > 0 ? '$_countdown' : '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                    return cell
                        .animate(target: _wrongIndex == index ? 1 : 0)
                        .shake(
                          duration: 200.ms,
                          hz: 5,
                          offset: const Offset(8, 0),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

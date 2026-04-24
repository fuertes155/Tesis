import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'common/game_results.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'common/game_intro.dart';
import 'common/game_scoring.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';

class StroopGame extends ConsumerStatefulWidget {
  final bool flowMode;
  final int? flowIndex;
  final int? flowTotal;
  final int? patientAge;

  const StroopGame({
    super.key,
    this.flowMode = false,
    this.flowIndex,
    this.flowTotal,
    this.patientAge,
  });

  @override
  ConsumerState<StroopGame> createState() => _StroopGameState();
}

class _StroopGameState extends ConsumerState<StroopGame> {
  static const int totalRounds = 20;
  int _currentRound = 0;
  int _score = 0;
  int _correctStreak = 0;
  int _correct = 0;
  int _wrong = 0;
  bool _showIntro = true;

  // Colors for the game
  final Map<String, Color> _colors = {
    'ROJO': Colors.red,
    'AZUL': Colors.blue,
    'VERDE': Colors.green,
    'AMARILLO': Colors.orange, // Using orange for better visibility than yellow
  };

  late String _wordText;
  late Color _wordColor;
  bool _isPlaying = false;
  DateTime? _lastTapTime;
  List<int> _reactionTimes = [];
  bool _pulseCorrect = false;
  bool _wrongShake = false;

  @override
  void initState() {
    super.initState();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _currentRound = 0;
      _score = 0;
      _correctStreak = 0;
      _reactionTimes = [];
      _correct = 0;
      _wrong = 0;
      _nextRound();
    });
  }

  void _nextRound() {
    if (_currentRound >= totalRounds) {
      _endGame();
      return;
    }

    final random = Random();
    final keys = _colors.keys.toList();

    // Pick random text
    String text = keys[random.nextInt(keys.length)];

    // Pick random color (can be same or different)
    Color color = _colors.values.elementAt(random.nextInt(_colors.length));

    setState(() {
      _wordText = text;
      _wordColor = color;
      _currentRound++;
      _lastTapTime = DateTime.now();
    });
  }

  void _handleInput(Color selectedColor) {
    if (!_isPlaying) return;

    final reactionTime = DateTime.now()
        .difference(_lastTapTime!)
        .inMilliseconds;
    _reactionTimes.add(reactionTime);

    bool isCorrect = selectedColor == _wordColor;

    setState(() {
      if (isCorrect) {
        HapticFeedback.lightImpact();
        _score += 10 + (_correctStreak * 2); // Bonus for streak
        _correctStreak++;
        _correct += 1;
      } else {
        HapticFeedback.vibrate();
        _correctStreak = 0;
        _wrong += 1;
      }
    });

    // Visual feedback flash
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 300),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        content: Text(
          isCorrect ? 'Correcto (+${10 + (_correctStreak * 2)})' : 'Incorrecto',
        ),
      ),
    );
    if (isCorrect) {
      setState(() {
        _pulseCorrect = true;
        _wrongShake = false;
      });
      Future.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        setState(() {
          _pulseCorrect = false;
        });
        _nextRound();
      });
    } else {
      setState(() {
        _wrongShake = true;
        _pulseCorrect = false;
      });
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() {
          _wrongShake = false;
        });
        _nextRound();
      });
    }
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
    });

    final avgReaction = _reactionTimes.isEmpty
        ? 0
        : _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
    final execScore = GameScoring.stroopExecutiveScore(
      correct: _correct,
      total: totalRounds,
      avgMs: avgReaction,
      age: widget.patientAge,
    );
    final attScore = GameScoring.reactionScoreFromAvgMs(
      avgReaction,
      age: widget.patientAge,
    );
    final global = ((execScore * 0.6) + (attScore * 0.4)).round();
    final details = <String, dynamic>{
      'Funciones Ejecutivas': execScore,
      'Atención': attScore,
    };
    final metrics = <String, dynamic>{
      'rounds': totalRounds,
      'correct': _correct,
      'wrong': _wrong,
      'avg_ms': avgReaction,
      'raw_score': _score,
    };
    final api = ref.read(apiServiceProvider).requireValue;
    final future = GameResults.sendGameResult(
      api: api,
      title: 'Resultados - Funciones Ejecutivas',
      score: global,
      details: details,
      gameKey: 'stroop',
      metrics: metrics,
      age: widget.patientAge,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Prueba Finalizada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Puntuación: $_score'),
            const SizedBox(height: 8),
            Text('Tiempo medio: $avgReaction ms'),
          ],
        ),
        actions: [
          if (!widget.flowMode)
            TextButton(
              onPressed: () {
                context.pop();
                GameResults.navigateToResults(
                  context,
                  title: 'Resultados - Funciones Ejecutivas',
                  score: global,
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
                    'title': 'Resultados - Funciones Ejecutivas',
                    'score': global,
                    'details': details,
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
              _startGame();
            },
            child: const Text('Intentar de Nuevo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro && !_isPlaying && _currentRound == 0) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.flowMode &&
                    widget.flowIndex != null &&
                    widget.flowTotal != null
                ? 'Funciones Ejecutivas (${widget.flowIndex! + 1}/${widget.flowTotal})'
                : 'Funciones Ejecutivas',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          centerTitle: false,
        ),
        body: GameIntro(
          title: 'Test Stroop',
          subtitle:
              'Evalúa el control inhibitorio y la velocidad de respuesta.',
          icon: Icons.psychology_alt,
          steps: const [
            'Verás una palabra (ROJO, AZUL, VERDE, AMARILLO) escrita con un color.',
            'Tu tarea es seleccionar el COLOR de la tinta, no la palabra.',
            'Responde lo más rápido posible sin equivocarte.',
            'Completa 20 rondas para finalizar.',
          ],
          actionLabel: 'Comenzar',
          onStart: () {
            setState(() => _showIntro = false);
            _startGame();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.flowMode &&
                  widget.flowIndex != null &&
                  widget.flowTotal != null
              ? 'Funciones Ejecutivas (${widget.flowIndex! + 1}/${widget.flowTotal})'
              : 'Funciones Ejecutivas ($_currentRound/$totalRounds)',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isPlaying) ...[
                const Icon(
                  Icons.psychology_alt,
                  size: 80,
                  color: Colors.purple,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Test Stroop',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecciona el COLOR de la tinta,\nno la palabra escrita.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _showIntro = false);
                    _startGame();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('COMENZAR'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(label: Text('Ronda: $_currentRound/$totalRounds')),
                    const SizedBox(width: 8),
                    Chip(label: Text('Puntos: $_score')),
                  ],
                ),
                const Spacer(),
                AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOut,
                        ),
                        child: ScaleTransition(
                          scale: Tween(begin: 0.98, end: 1.0).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Container(
                        key: ValueKey('${_wordText}_${_wordColor.toARGB32()}'),
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          _wordText,
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: _wordColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    )
                    .animate(target: _pulseCorrect ? 1 : 0)
                    .scale(
                      duration: 160.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.06, 1.06),
                      curve: Curves.easeOut,
                    )
                    .animate(target: _wrongShake ? 1 : 0)
                    .shake(duration: 180.ms, hz: 5, offset: const Offset(8, 0)),
                const Spacer(),
                Text(
                  'Selecciona el color:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _colors.entries.map((entry) {
                    return _ColorButton(
                      color: entry.value,
                      onTap: () => _handleInput(entry.value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Ink(
          width: 70,
          height: 70,
          decoration: ShapeDecoration(
            color: color,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 4),
            ),
            shadows: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'common/game_results.dart';
import 'common/game_intro.dart';
import 'common/game_scoring.dart';
import '../widgets/animated_dialog.dart';

class ReactionGame extends StatefulWidget {
  final bool flowMode;
  final int? flowIndex;
  final int? flowTotal;
  final int? patientAge;

  const ReactionGame({
    super.key,
    this.flowMode = false,
    this.flowIndex,
    this.flowTotal,
    this.patientAge,
  });

  @override
  State<ReactionGame> createState() => _ReactionGameState();
}

enum GameState { waiting, ready, tooEarly, result }

class _ReactionGameState extends State<ReactionGame> {
  GameState _state = GameState.waiting;
  Color _backgroundColor = Colors.red;
  String _message = 'Esperar...';
  DateTime? _startTime;
  final List<int> _times = [];
  Timer? _timer;
  static const int totalAttempts = 5;
  int _best = 0;
  double _iconScale = 1.0;
  bool _started = false;
  int _tooEarly = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    setState(() {
      _started = true;
      _state = GameState.waiting;
      _backgroundColor = Colors.redAccent;
      _message = 'Esperar...';
    });

    int delay = Random().nextInt(3000) + 2000; // 2 to 5 seconds
    _timer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() {
          _state = GameState.ready;
          _backgroundColor = Colors.green;
          _message = '¡AHORA!';
          _startTime = DateTime.now();
        });
      }
    });
  }

  void _handleTap() {
    if (_state == GameState.waiting) {
      _timer?.cancel();
      setState(() {
        _state = GameState.tooEarly;
        _backgroundColor = Colors.orange;
        _message = '¡Muy rápido! Toca para intentar de nuevo.';
        _tooEarly += 1;
      });
    } else if (_state == GameState.ready) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_startTime!).inMilliseconds;
      _times.add(duration);
      if (_best == 0 || duration < _best) {
        _best = duration;
      }

      setState(() {
        _iconScale = 1.08;
        _state = GameState.result;
        _backgroundColor = Colors.blue;
        _message = '$duration ms\nToca para continuar';
      });
      Timer(const Duration(milliseconds: 140), () {
        if (mounted) {
          setState(() {
            _iconScale = 1.0;
          });
        }
      });

      if (_times.length >= totalAttempts) {
        _finishGame();
      }
    } else if (_state == GameState.tooEarly || _state == GameState.result) {
      if (_times.length < totalAttempts) {
        _startRound();
      } else {
        _finishGame();
      }
    }
  }

  void _finishGame() {
    int average = _times.isEmpty
        ? 0
        : _times.reduce((a, b) => a + b) ~/ _times.length;
    final score = GameScoring.reactionScoreFromAvgMs(
      average,
      age: widget.patientAge,
      penalty: _tooEarly * 5,
    );
    final details = <String, dynamic>{
      'Atención': score,
      'Funciones Ejecutivas': (score - 8).clamp(20, 100),
    };
    final metrics = <String, dynamic>{
      'avg_ms': average,
      'best_ms': _best,
      'attempts': _times.length,
      'too_early': _tooEarly,
    };
    final future = GameResults.sendGameResult(
      title: 'Resultados - Atención',
      score: score,
      details: details,
      gameKey: 'reaction',
      metrics: metrics,
      age: widget.patientAge,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedDialog(
        child: AlertDialog(
          title: const Text('Prueba de Atención Finalizada'),
          content: Text(
            'Promedio de reacción: $average ms\nIntentos: ${_times.length}',
          ),
          actions: [
            if (!widget.flowMode)
              TextButton(
                onPressed: () {
                  context.pop();
                  GameResults.navigateToResults(
                    context,
                    title: 'Resultados - Atención',
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
                      'title': 'Resultados - Atención',
                      'score': score,
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
                setState(() {
                  _times.clear();
                  _started = false;
                  _tooEarly = 0;
                });
              },
              child: const Text('Reiniciar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
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
                ? 'Atención (${widget.flowIndex! + 1}/${widget.flowTotal})'
                : 'Atención',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          centerTitle: false,
        ),
        body: GameIntro(
          title: 'Atención Sostenida',
          subtitle: 'Mide tu tiempo de reacción y control de impulsos.',
          icon: Icons.timer_outlined,
          steps: const [
            'Mantén la vista en la pantalla y espera.',
            'Cuando el fondo cambie a VERDE, toca lo más rápido que puedas.',
            'Si tocas antes de tiempo, el intento cuenta como error.',
            'Completa 5 intentos para finalizar la prueba.',
          ],
          actionLabel: 'Comenzar',
          onStart: _startRound,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.flowMode &&
                  widget.flowIndex != null &&
                  widget.flowTotal != null
              ? 'Atención (${widget.flowIndex! + 1}/${widget.flowTotal})'
              : 'Atención (${_times.length}/$totalAttempts)',
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: _backgroundColor,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _iconScale,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Icon(
                  _state == GameState.ready ? Icons.touch_app : Icons.timer,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _message,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_times.isNotEmpty)
                Text(
                  'Mejor: $_best ms | Promedio: ${_times.reduce((a, b) => a + b) ~/ _times.length} ms',
                  style: const TextStyle(color: Colors.white70),
                ),
              if (_state == GameState.waiting)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Toca la pantalla cuando se ponga VERDE',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

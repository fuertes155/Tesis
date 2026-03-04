import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'common/game_results.dart';
import '../widgets/animated_dialog.dart';

class ReactionGame extends StatefulWidget {
  const ReactionGame({super.key});

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

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    setState(() {
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
    GameResults.sendSession(
      patientId: 1,
      status: 'completed',
      notes:
          'reaction average=$average ms best=$_best ms attempts=${_times.length}',
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
                setState(() {
                  _times.clear();
                });
                _startRound();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Atención (${_times.length}/$totalAttempts)'),
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

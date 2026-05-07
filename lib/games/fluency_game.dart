import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'common/game_results.dart';
import 'common/game_intro.dart';
import 'common/game_scoring.dart';
import '../widgets/animated_dialog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/api_providers.dart';

class FluencyGame extends ConsumerStatefulWidget {
  final bool flowMode;
  final int? flowIndex;
  final int? flowTotal;
  final int? patientAge;

  const FluencyGame({
    super.key,
    this.flowMode = false,
    this.flowIndex,
    this.flowTotal,
    this.patientAge,
  });

  @override
  ConsumerState<FluencyGame> createState() => _FluencyGameState();
}

class _FluencyGameState extends ConsumerState<FluencyGame> {
  static const int gameDuration = 60; // seconds
  int _timeLeft = gameDuration;
  int _wordCount = 0;
  bool _isPlaying = false;
  bool _isFinished = false;
  String _currentPrompt = '';
  Timer? _timer;
  bool _isPaused = false;
  bool _showIntro = true;
  bool _isFocusMode = false;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }
  final List<String> _letters = ['F', 'A', 'S', 'M', 'R', 'P'];
  final List<String> _categories = [
    'Animales',
    'Frutas',
    'Ciudades',
    'Profesiones',
  ];

  void _startListening() async {
    if (!_speechEnabled) return;
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      localeId: 'es_ES',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  final Set<String> _countedWords = {};

  void _onSpeechResult(result) {
    if (result.finalResult || result.recognizedWords.isNotEmpty) {
      final text = result.recognizedWords.toLowerCase();
      final words = text.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
      
      int newCount = 0;
      for (final w in words) {
        if (!_countedWords.contains(w)) {
          _countedWords.add(w);
          newCount++;
        }
      }
      
      if (newCount > 0) {
        HapticFeedback.heavyImpact();
        setState(() {
          _wordCount += newCount;
          _lastWords = result.recognizedWords;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame(bool isCategory) {
    _countedWords.clear();
    _lastWords = '';
    setState(() {
      _currentPrompt = isCategory
          ? _categories[Random().nextInt(_categories.length)]
          : 'Letra: ${_letters[Random().nextInt(_letters.length)]}';
      _timeLeft = gameDuration;
      _wordCount = 0;
      _isPlaying = true;
      _gameStartTime = DateTime.now();
      _isFinished = false;
      _isPaused = false;
    });

    if (_speechEnabled) {
      _startListening();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isPaused) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    if (_isListening) {
      _stopListening();
    }
    setState(() {
      _isPlaying = false;
      _isFinished = true;
      _isPaused = false;
    });
    _showResultDialog();
  }

  void _incrementCount() {
    if (_isFocusMode) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _wordCount++;
    });
  }

  void _decrementCount() {
    if (_wordCount > 0) {
      if (_isFocusMode) {
        HapticFeedback.vibrate();
      } else {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _wordCount--;
      });
    }
  }

  void _showResultDialog() {
    final score = GameScoring.fluencyScore(_wordCount, age: widget.patientAge);
    final details = <String, dynamic>{
      'Lenguaje': score,
      'Funciones Ejecutivas': (score - 8).clamp(20, 100),
    };
    final metrics = <String, dynamic>{
      'count': _wordCount,
      'prompt': _currentPrompt,
      'duration_s': gameDuration - _timeLeft,
      'paused': _isPaused,
    };
    final api = ref.read(apiServiceProvider).value!;
    final durationMs = _gameStartTime != null
        ? DateTime.now().difference(_gameStartTime!).inMilliseconds
        : 0;
    final future = GameResults.sendGameResult(
      api: api,
      title: 'Resultados - Lenguaje',
      score: score,
      details: details,
      gameKey: 'fluency',
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
          content: Text('Palabras generadas: $_wordCount'),
          actions: [
            if (!widget.flowMode)
              TextButton(
                onPressed: () {
                  context.pop();
                  GameResults.navigateToResults(
                    context,
                    title: 'Resultados - Lenguaje',
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
                      'title': 'Resultados - Lenguaje',
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
                  _isFinished = false;
                  _currentPrompt = '';
                });
              },
              child: const Text('Nueva Prueba'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_showIntro && !_isPlaying && !_isFinished) {
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
                ? 'Fluidez Verbal (${widget.flowIndex! + 1}/${widget.flowTotal})'
                : 'Fluidez Verbal',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          centerTitle: false,
        ),
        body: GameIntro(
          title: 'Fluidez Verbal',
          subtitle:
              'Mide cuántas palabras puedes generar en un tiempo limitado.',
          icon: Icons.record_voice_over_outlined,
          steps: const [
            'Elige el tipo de prueba: Fonológica (por letra) o Semántica (por categoría).',
            'Tienes 60 segundos para decir la mayor cantidad de palabras posibles.',
            'No repitas palabras y evita nombres propios si no corresponden.',
            'Usa los botones + y − para registrar el número de palabras.',
          ],
          actionLabel: 'Elegir tipo de prueba',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isFocusMode
            ? const Text('Modo Enfoque')
            : Text(
                widget.flowMode &&
                        widget.flowIndex != null &&
                        widget.flowTotal != null
                    ? 'Fluidez Verbal (${widget.flowIndex! + 1}/${widget.flowTotal})'
                    : 'Fluidez Verbal',
              ),
        actions: [
          IconButton(
            icon: Icon(_isFocusMode ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _isFocusMode = !_isFocusMode),
            tooltip: _isFocusMode ? 'Desactivar Enfoque' : 'Activar Enfoque',
          ),
          if (_isPlaying)
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: () {
                setState(() {
                  _isPaused = !_isPaused;
                });
              },
              tooltip: _isPaused ? 'Reanudar' : 'Pausar',
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isPlaying && !_isFinished) ...[
                if (!_isFocusMode) ...[
                  const Icon(
                    Icons.record_voice_over_outlined,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                ],
                Text(
                  'Selecciona el tipo de prueba',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _GameModeCard(
                        title: 'Fonológica',
                        subtitle: _isFocusMode ? '' : 'Palabras con una letra',
                        icon: Icons.abc,
                        onTap: () => _startGame(false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _GameModeCard(
                        title: 'Semántica',
                        subtitle: _isFocusMode ? '' : 'Palabras de una categoría',
                        icon: Icons.category_outlined,
                        onTap: () => _startGame(true),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  _currentPrompt,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_isFocusMode)
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _timeLeft / gameDuration,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isListening ? Colors.blue : (_timeLeft > 10 ? Colors.green : Colors.red),
                          ),
                        ),
                      ),
                    if (_isListening && !_isFocusMode)
                      const SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                    Text(
                      '$_timeLeft',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: _isFocusMode ? 120 : 80,
                        color: _isListening ? Colors.blue : null,
                      ),
                    ),
                    if (_isPaused)
                      const Positioned(
                        bottom: 8,
                        child: Text(
                          'PAUSA',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_lastWords.isNotEmpty && !_isFocusMode) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Última palabra: $_lastWords',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                if (!_isFocusMode) ...[
                  Text('Conteo de Palabras', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: 'dec',
                      onPressed: _isPlaying && !_isPaused
                          ? _decrementCount
                          : null,
                      backgroundColor: _isFocusMode ? Colors.transparent : Colors.red[100],
                      elevation: _isFocusMode ? 0 : 4,
                      shape: _isFocusMode ? const CircleBorder(side: BorderSide(color: Colors.red, width: 1)) : null,
                      child: const Icon(Icons.remove, color: Colors.red),
                    ),
                    const SizedBox(width: 32),
                    Text(
                      '$_wordCount',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: _isFocusMode ? 100 : 72,
                      ),
                    ),
                    const SizedBox(width: 32),
                    FloatingActionButton(
                      heroTag: 'inc',
                      onPressed: _isPlaying && !_isPaused
                          ? _incrementCount
                          : null,
                      backgroundColor: _isFocusMode ? Colors.transparent : Colors.green[100],
                      elevation: _isFocusMode ? 0 : 4,
                      shape: _isFocusMode ? const CircleBorder(side: BorderSide(color: Colors.green, width: 1)) : null,
                      child: const Icon(Icons.add, color: Colors.green),
                    ),
                  ],
                ),
                const Spacer(),
                if (_isPlaying && !_isFocusMode)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _endGame,
                      child: const Text('Finalizar Ahora'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GameModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Agrupación de resultados de juegos para la gráfica de evolución cognitiva.
///
/// Es lógica pura (sin widgets) para poder probarla de forma unitaria.
library;

/// Juegos que se grafican, en el orden de la leyenda, con su dominio cognitivo.
const dominiosEvolucion = <String, String>{
  'visual_memory': 'Memoria',
  'reaction': 'Atención',
  'stroop': 'Funciones ejecutivas',
  'fluency': 'Lenguaje',
};

class EvolucionCognitiva {
  const EvolucionCognitiva({required this.fechas, required this.puntajes});

  /// Días con evaluación, del más antiguo al más reciente.
  final List<DateTime> fechas;

  /// Por juego, el puntaje de cada día de [fechas] (null si ese día no se aplicó).
  /// Solo incluye juegos con al menos un puntaje, en el orden de [dominiosEvolucion].
  final Map<String, List<double?>> puntajes;

  bool get vacia => fechas.isEmpty;
  List<String> get juegos => puntajes.keys.toList();
}

/// El backend guarda los timestamps en UTC sin zona horaria; se pasan a hora local.
DateTime? fechaLocalDesdeApi(Object? raw) {
  final texto = raw?.toString();
  if (texto == null || texto.isEmpty) return null;
  final conZona = texto.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(texto);
  return DateTime.tryParse(conZona ? texto : '${texto}Z')?.toLocal();
}

/// Agrupa los resultados por día de evaluación y por juego.
///
/// [resultados] llega de `/sessions/results/latest` (del más reciente al más
/// antiguo): si un juego se repitió el mismo día, se conserva el más reciente.
/// Se ignoran juegos desconocidos y registros sin puntaje o sin fecha válida.
EvolucionCognitiva agruparEvolucion(List<dynamic> resultados) {
  final porDia = <DateTime, Map<String, double>>{};
  for (final r in resultados) {
    if (r is! Map) continue;
    final juego = r['game_name']?.toString();
    final fecha = fechaLocalDesdeApi(r['timestamp']);
    final score = r['score'];
    if (juego == null || !dominiosEvolucion.containsKey(juego) || fecha == null || score is! num) {
      continue;
    }
    porDia
        .putIfAbsent(DateTime(fecha.year, fecha.month, fecha.day), () => {})
        .putIfAbsent(juego, () => score.toDouble());
  }

  final fechas = porDia.keys.toList()..sort();
  final puntajes = <String, List<double?>>{};
  for (final juego in dominiosEvolucion.keys) {
    final serie = [for (final f in fechas) porDia[f]![juego]];
    if (serie.any((v) => v != null)) puntajes[juego] = serie;
  }
  return EvolucionCognitiva(fechas: fechas, puntajes: puntajes);
}

import 'package:flutter_application_1/core/utils/search_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchUtils.normalize', () {
    test('quita tildes, pasa a minúsculas y recorta espacios', () {
      expect(SearchUtils.normalize('  María Fernanda RÍOS  '), 'maria fernanda rios');
      expect(SearchUtils.normalize('Muñoz Patiño'), 'munoz patino');
    });

    test('un texto vacío queda vacío', () {
      expect(SearchUtils.normalize(''), '');
    });
  });

  group('SearchUtils.matches', () {
    test('encuentra sin importar tildes ni mayúsculas', () {
      expect(SearchUtils.matches('Héctor Fabio Arango', 'hector'), isTrue);
      expect(SearchUtils.matches('Andrés Gómez', 'GOMEZ'), isTrue);
      expect(SearchUtils.matches('Demencia vascular', 'alzheimer'), isFalse);
    });

    test('una búsqueda vacía coincide con todo', () {
      expect(SearchUtils.matches('Cualquier nombre', ''), isTrue);
    });
  });
}

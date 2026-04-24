import 'package:diacritic/diacritic.dart';

class SearchUtils {
  /// Normaliza un string eliminando acentos, diacríticos y convirtiéndolo a minúsculas
  /// para facilitar búsquedas "fuzzy" o insensibles a tildes.
  static String normalize(String text) {
    if (text.isEmpty) return '';
    return removeDiacritics(text).toLowerCase().trim();
  }

  /// Verifica si el [nombre] coincide con el [query] ignorando tildes y mayúsculas.
  static bool matches(String name, String query) {
    if (query.isEmpty) return true;
    final normalizedName = normalize(name);
    final normalizedQuery = normalize(query);
    return normalizedName.contains(normalizedQuery);
  }
}

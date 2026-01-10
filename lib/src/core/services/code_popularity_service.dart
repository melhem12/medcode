import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CodePopularityService {
  static const String _key = 'code_popularity';
  final SharedPreferences _prefs;

  CodePopularityService(this._prefs);

  /// Increment view count for a code
  Future<void> incrementViewCount(String codeId) async {
    try {
      final popularity = await getPopularityMap();
      popularity[codeId] = (popularity[codeId] ?? 0) + 1;
      await _prefs.setString(_key, jsonEncode(popularity));
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  /// Get view count for a specific code
  Future<int> getViewCount(String codeId) async {
    final popularity = await getPopularityMap();
    return popularity[codeId] ?? 0;
  }

  /// Get popularity map (codeId -> viewCount)
  Future<Map<String, int>> getPopularityMap() async {
    try {
      final jsonString = _prefs.getString(_key);
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print('Error loading popularity map: $e');
      return {};
    }
  }

  /// Get top N popular code IDs sorted by view count
  Future<List<String>> getTopPopularCodes(int limit) async {
    final popularity = await getPopularityMap();
    final sorted = popularity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Clear all popularity data
  Future<void> clearPopularity() async {
    await _prefs.remove(_key);
  }

  /// Remove popularity for a specific code
  Future<void> removeCode(String codeId) async {
    final popularity = await getPopularityMap();
    popularity.remove(codeId);
    await _prefs.setString(_key, jsonEncode(popularity));
  }
}














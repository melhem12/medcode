import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchItem {
  final String codeId;
  final String code;
  final String description;
  final String? pageMarker;
  final DateTime timestamp;

  RecentSearchItem({
    required this.codeId,
    required this.code,
    required this.description,
    this.pageMarker,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'codeId': codeId,
      'code': code,
      'description': description,
      'pageMarker': pageMarker,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RecentSearchItem.fromJson(Map<String, dynamic> json) {
    return RecentSearchItem(
      codeId: json['codeId'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      pageMarker: json['pageMarker'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class RecentSearchesService {
  static const String _key = 'recent_searches';
  static const int _maxItems = 10; // Keep last 10 searches

  final SharedPreferences _prefs;

  RecentSearchesService(this._prefs);

  /// Save a search to recent searches
  Future<void> saveSearch({
    required String codeId,
    required String code,
    required String description,
    String? pageMarker,
  }) async {
    try {
      final searches = await getRecentSearches();
      
      // Remove duplicate if exists (same codeId)
      searches.removeWhere((item) => item.codeId == codeId);
      
      // Add new search at the beginning
      searches.insert(0, RecentSearchItem(
        codeId: codeId,
        code: code,
        description: description,
        pageMarker: pageMarker,
        timestamp: DateTime.now(),
      ));
      
      // Keep only the most recent items
      if (searches.length > _maxItems) {
        searches.removeRange(_maxItems, searches.length);
      }
      
      // Save to SharedPreferences
      final jsonList = searches.map((item) => item.toJson()).toList();
      await _prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      // Handle error silently
      print('Error saving recent search: $e');
    }
  }

  /// Get all recent searches, sorted by most recent first
  Future<List<RecentSearchItem>> getRecentSearches() async {
    try {
      final jsonString = _prefs.getString(_key);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => RecentSearchItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading recent searches: $e');
      return [];
    }
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches() async {
    await _prefs.remove(_key);
  }

  /// Remove a specific search by codeId
  Future<void> removeSearch(String codeId) async {
    try {
      final searches = await getRecentSearches();
      searches.removeWhere((item) => item.codeId == codeId);
      
      final jsonList = searches.map((item) => item.toJson()).toList();
      await _prefs.setString(_key, jsonEncode(jsonList));
    } catch (e) {
      print('Error removing search: $e');
    }
  }
}














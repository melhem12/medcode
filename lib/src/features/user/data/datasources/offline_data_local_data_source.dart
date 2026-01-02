import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

abstract class OfflineDataLocalDataSource {
  Future<Map<String, dynamic>> getSyncStatus();
  Future<void> setSyncStatus(Map<String, dynamic> status);
  Future<List<String>> getDownloadedCategories();
  Future<void> setCategoryDownloaded(String category, bool downloaded);
  Future<int> getCategorySize(String category);
  Future<void> setCategorySize(String category, int size);
  Future<void> clearAllOfflineData();
}

class OfflineDataLocalDataSourceImpl implements OfflineDataLocalDataSource {
  final SharedPreferences prefs;

  OfflineDataLocalDataSourceImpl(this.prefs);

  @override
  Future<Map<String, dynamic>> getSyncStatus() async {
    final statusJson = prefs.getString('sync_status');
    if (statusJson == null) {
      return {
        'last_sync': null,
        'is_syncing': false,
      };
    }
    try {
      return jsonDecode(statusJson) as Map<String, dynamic>;
    } catch (_) {
      return {
        'last_sync': null,
        'is_syncing': false,
      };
    }
  }

  @override
  Future<void> setSyncStatus(Map<String, dynamic> status) async {
    await prefs.setString('sync_status', jsonEncode(status));
  }

  @override
  Future<List<String>> getDownloadedCategories() async {
    final categoriesJson = prefs.getString('downloaded_categories');
    if (categoriesJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> setCategoryDownloaded(String category, bool downloaded) async {
    final categories = await getDownloadedCategories();
    if (downloaded && !categories.contains(category)) {
      categories.add(category);
    } else if (!downloaded) {
      categories.remove(category);
    }
    await prefs.setString('downloaded_categories', jsonEncode(categories));
  }

  @override
  Future<int> getCategorySize(String category) async {
    return prefs.getInt('category_size_$category') ?? 0;
  }

  @override
  Future<void> setCategorySize(String category, int size) async {
    await prefs.setInt('category_size_$category', size);
  }

  @override
  Future<void> clearAllOfflineData() async {
    await prefs.remove('sync_status');
    await prefs.remove('downloaded_categories');
    await prefs.remove('cached_medical_codes'); // Clear medical codes cache
    await prefs.remove('cached_contents'); // Clear contents cache
    // Clear all category sizes
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('category_size_')) {
        await prefs.remove(key);
      }
    }
  }
}


















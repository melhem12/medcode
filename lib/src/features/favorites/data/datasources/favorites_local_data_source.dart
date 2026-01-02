import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

abstract class FavoritesLocalDataSource {
  Future<void> addFavorite(String codeId);
  Future<void> removeFavorite(String codeId);
  Future<bool> isFavorite(String codeId);
  Future<List<String>> getFavoriteCodeIds();
  Future<void> clearFavorites();
}

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  final SharedPreferences prefs;
  static const String _favoritesKey = 'favorite_code_ids';

  FavoritesLocalDataSourceImpl(this.prefs);

  @override
  Future<void> addFavorite(String codeId) async {
    final favorites = await getFavoriteCodeIds();
    if (!favorites.contains(codeId)) {
      favorites.add(codeId);
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
    }
  }

  @override
  Future<void> removeFavorite(String codeId) async {
    final favorites = await getFavoriteCodeIds();
    favorites.remove(codeId);
    await prefs.setString(_favoritesKey, jsonEncode(favorites));
  }

  @override
  Future<bool> isFavorite(String codeId) async {
    final favorites = await getFavoriteCodeIds();
    return favorites.contains(codeId);
  }

  @override
  Future<List<String>> getFavoriteCodeIds() async {
    final favoritesJson = prefs.getString(_favoritesKey);
    if (favoritesJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearFavorites() async {
    await prefs.remove(_favoritesKey);
  }
}



















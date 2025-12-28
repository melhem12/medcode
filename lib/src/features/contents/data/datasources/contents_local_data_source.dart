import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_node_model.dart';
import '../../domain/entities/content_node.dart';

abstract class ContentsLocalDataSource {
  Future<void> cacheContents(List<ContentNode> contents);
  Future<List<ContentNode>> getCachedContents();
}

class ContentsLocalDataSourceImpl implements ContentsLocalDataSource {
  static const String _cacheKey = 'cached_contents';
  final SharedPreferences prefs;

  ContentsLocalDataSourceImpl(this.prefs);

  @override
  Future<void> cacheContents(List<ContentNode> contents) async {
    final payload = contents.map(_contentToJson).toList();
    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  @override
  Future<List<ContentNode>> getCachedContents() async {
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => ContentNodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _contentToJson(ContentNode node) {
    return {
      'id': node.id,
      'title': node.title,
      'level': node.level,
      'section_label': node.sectionLabel,
      'page_marker': node.pageMarker,
      'code_hint': node.codeHint,
      'parent_id': node.parentId,
      'children': node.children.map(_contentToJson).toList(),
    };
  }
}

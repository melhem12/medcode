/// Transforms exported data to match the import file structure
class ExportDataTransformer {
  /// Transform medical codes to import format
  /// Import expects: Column A = code, Column B = description
  static List<Map<String, dynamic>> transformMedicalCodes(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map((row) {
      return {
        'code': row['code']?.toString() ?? '',
        'description': row['description']?.toString() ?? '',
      };
    }).toList();
  }

  /// Transform contents to import format
  /// Import expects:
  /// Column A = section_label
  /// Column B = system_title (section)
  /// Column C = category_title (subcategory)
  /// Column D = subcategory_title (subcategory)
  /// Column E = code_hint
  /// Column F = page_marker
  static List<Map<String, dynamic>> transformContents(
    List<Map<String, dynamic>> rawData,
  ) {
    // Build a tree structure first
    final Map<int, Map<String, dynamic>> nodeMap = {};
    final List<Map<String, dynamic>> result = [];

    // First pass: create node map
    for (final row in rawData) {
      final id = _parseInt(row['id']);
      if (id == null) continue; // Skip rows without valid ID
      
      final parentId = row['parent_id'] != null ? _parseInt(row['parent_id']) : null;
      
      nodeMap[id] = {
        'id': id,
        'title': row['title']?.toString() ?? '',
        'level': row['level']?.toString() ?? '',
        'section_label': row['section_label']?.toString(),
        'parent_id': parentId,
        'page_marker': row['page_marker']?.toString(),
        'code_hint': row['code_hint']?.toString(),
        'children': <Map<String, dynamic>>[],
      };
    }

    // Second pass: build tree
    for (final node in nodeMap.values) {
      final parentId = node['parent_id'] as int?;
      if (parentId != null && nodeMap.containsKey(parentId)) {
        final parentNode = nodeMap[parentId];
        if (parentNode != null) {
          final children = parentNode['children'] as List<Map<String, dynamic>>;
          children.add(node);
        }
      }
    }

    // Third pass: flatten to import format
    for (final node in nodeMap.values) {
      if (node['parent_id'] == null) {
        // Root node (section)
        _addNodeToResult(node, nodeMap, result);
      }
    }

    return result;
  }

  static void _addNodeToResult(
    Map<String, dynamic> node,
    Map<int, Map<String, dynamic>> nodeMap,
    List<Map<String, dynamic>> result,
  ) {
    final level = node['level'] as String? ?? '';
    final title = node['title']?.toString() ?? '';
    final sectionLabel = node['section_label']?.toString() ?? '';
    final codeHint = node['code_hint']?.toString() ?? '';
    final pageMarker = node['page_marker']?.toString() ?? '';
    final children = node['children'] as List<Map<String, dynamic>>;

    if (level == 'section') {
      // Section row: A=section_label, B=title, C=empty, D=empty, E=code_hint, F=page_marker
      result.add({
        'section_label': sectionLabel,
        'system_title': title,
        'category_title': '',
        'subcategory_title': '',
        'code_hint': codeHint,
        'page_marker': pageMarker,
      });

      // Add children (subcategories)
      for (final child in children) {
        _addNodeToResult(child, nodeMap, result);
      }
    } else if (level == 'subcategory') {
      // Subcategory row: A=section_label, B=empty, C=title (if parent is section), D=title (if parent is subcategory), E=code_hint, F=page_marker
      final parentId = node['parent_id'] as int?;
      final parent = parentId != null ? nodeMap[parentId] : null;
      final parentLevel = parent?['level'] as String? ?? '';

      if (parentLevel == 'section') {
        // Category under section: A=section_label, B=empty, C=title, D=empty, E=code_hint, F=page_marker
        result.add({
          'section_label': sectionLabel,
          'system_title': '',
          'category_title': title,
          'subcategory_title': '',
          'code_hint': codeHint,
          'page_marker': pageMarker,
        });
      } else {
        // Subcategory under category: A=section_label, B=empty, C=empty, D=title, E=code_hint, F=page_marker
        result.add({
          'section_label': sectionLabel,
          'system_title': '',
          'category_title': '',
          'subcategory_title': title,
          'code_hint': codeHint,
          'page_marker': pageMarker,
        });
      }

      // Add children (nested subcategories)
      for (final child in children) {
        _addNodeToResult(child, nodeMap, result);
      }
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }
}


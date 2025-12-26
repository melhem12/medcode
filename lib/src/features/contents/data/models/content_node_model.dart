import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/content_node.dart';

// part 'content_node_model.g.dart'; // Using manual serialization

@JsonSerializable()
class ContentNodeModel extends ContentNode {
  ContentNodeModel({
    required super.id,
    required super.title,
    required super.level,
    @JsonKey(name: 'section_label') super.sectionLabel,
    @JsonKey(name: 'page_marker') super.pageMarker,
    @JsonKey(name: 'code_hint') super.codeHint,
    @JsonKey(name: 'parent_id') super.parentId,
    List<ContentNode>? children,
  }) : super(children: children ?? []);

  factory ContentNodeModel.fromJson(Map<String, dynamic> json) {
    final children = (json['children'] as List<dynamic>?)
            ?.map((e) => ContentNodeModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ContentNodeModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      level: json['level'] as String,
      sectionLabel: json['section_label'] as String?,
      pageMarker: json['page_marker'] as String?,
      codeHint: json['code_hint'] as String?,
      parentId: json['parent_id'] as int?,
      children: children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'level': level,
      'section_label': sectionLabel,
      'page_marker': pageMarker,
      'code_hint': codeHint,
      'parent_id': parentId,
      'children': children.map((e) => (e as ContentNodeModel).toJson()).toList(),
    };
  }
}


class ContentNode {
  final String id;
  final String title;
  final String level;
  final String? sectionLabel;
  final String? pageMarker;
  final String? codeHint;
  final int? parentId;
  final List<ContentNode> children;

  ContentNode({
    required this.id,
    required this.title,
    required this.level,
    this.sectionLabel,
    this.pageMarker,
    this.codeHint,
    this.parentId,
    this.children = const [],
  });
}





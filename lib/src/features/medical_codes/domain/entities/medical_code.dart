class MedicalCode {
  final String id;
  final String code;
  final String description;
  final String? category;
  final String? bodySystem;
  final String? contentId;
  final String? pageMarker;
  final String? flags;
  final double? aValue;
  final double? sValue;
  final String? sectionDetected;
  final String? subsectionDetected;
  final String? subsubsectionDetected;
  final String? level4Detected;

  MedicalCode({
    required this.id,
    required this.code,
    required this.description,
    this.category,
    this.bodySystem,
    this.contentId,
    this.pageMarker,
    this.flags,
    this.aValue,
    this.sValue,
    this.sectionDetected,
    this.subsectionDetected,
    this.subsubsectionDetected,
    this.level4Detected,
  });
}


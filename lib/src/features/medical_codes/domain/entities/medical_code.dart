class MedicalCode {
  final String id;
  final String code;
  final String description;
  final String? category;
  final String? bodySystem;
  final String? contentId;
  final String? pageMarker;

  MedicalCode({
    required this.id,
    required this.code,
    required this.description,
    this.category,
    this.bodySystem,
    this.contentId,
    this.pageMarker,
  });
}


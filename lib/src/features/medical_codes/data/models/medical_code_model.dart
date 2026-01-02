import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/medical_code.dart';

part 'medical_code_model.g.dart';

@JsonSerializable()
class MedicalCodeModel extends MedicalCode {
  @override
  @JsonKey(name: 'body_system')
  String? get bodySystem => super.bodySystem;
  
  @override
  @JsonKey(name: 'content_id')
  String? get contentId => super.contentId;
  
  @override
  @JsonKey(name: 'page_marker')
  String? get pageMarker => super.pageMarker;
  
  @override
  @JsonKey(name: 'a_value')
  double? get aValue => super.aValue;
  
  @override
  @JsonKey(name: 's_value')
  double? get sValue => super.sValue;
  
  @override
  @JsonKey(name: 'section_detected')
  String? get sectionDetected => super.sectionDetected;
  
  @override
  @JsonKey(name: 'subsection_detected')
  String? get subsectionDetected => super.subsectionDetected;
  
  @override
  @JsonKey(name: 'subsubsection_detected')
  String? get subsubsectionDetected => super.subsubsectionDetected;
  
  @override
  @JsonKey(name: 'level4_detected')
  String? get level4Detected => super.level4Detected;

  MedicalCodeModel({
    required super.id,
    required super.code,
    required super.description,
    super.category,
    super.bodySystem,
    super.contentId,
    super.pageMarker,
    super.flags,
    super.aValue,
    super.sValue,
    super.sectionDetected,
    super.subsectionDetected,
    super.subsubsectionDetected,
    super.level4Detected,
  });

  factory MedicalCodeModel.fromJson(Map<String, dynamic> json) {
    print('MedicalCodeModel.fromJson received: $json');
    
    // Handle id as int or String - backend sends int
    final idValue = json['id'];
    final idString = idValue is int ? idValue.toString() : (idValue as String? ?? '');
    print('id value type: ${idValue.runtimeType}, value: $idValue, converted: $idString');
    
    // Handle content_id as int or String - backend sends int
    final contentIdValue = json['content_id'];
    final contentIdString = contentIdValue is int 
        ? contentIdValue.toString() 
        : (contentIdValue as String?);
    print('content_id value type: ${contentIdValue.runtimeType}, value: $contentIdValue, converted: $contentIdString');
    
    // Handle numeric values that might be int, double, or null
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed;
      }
      return null;
    }
    
    return MedicalCodeModel(
      id: idString,
      code: json['code'] as String,
      description: json['description'] as String,
      category: json['category'] as String?,
      bodySystem: json['body_system'] as String?,
      contentId: contentIdString,
      pageMarker: json['page_marker'] as String?,
      flags: json['flags'] as String?,
      aValue: parseDouble(json['a_value']),
      sValue: parseDouble(json['s_value']),
      sectionDetected: json['section_detected'] as String?,
      subsectionDetected: json['subsection_detected'] as String?,
      subsubsectionDetected: json['subsubsection_detected'] as String?,
      level4Detected: json['level4_detected'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$MedicalCodeModelToJson(this);
}


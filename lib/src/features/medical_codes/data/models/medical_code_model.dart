import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/medical_code.dart';

part 'medical_code_model.g.dart';

@JsonSerializable()
class MedicalCodeModel extends MedicalCode {
  @JsonKey(name: 'body_system')
  String? get bodySystem => super.bodySystem;
  
  @JsonKey(name: 'content_id')
  String? get contentId => super.contentId;
  
  @JsonKey(name: 'page_marker')
  String? get pageMarker => super.pageMarker;

  MedicalCodeModel({
    required super.id,
    required super.code,
    required super.description,
    super.category,
    super.bodySystem,
    super.contentId,
    super.pageMarker,
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
    
    return MedicalCodeModel(
      id: idString,
      code: json['code'] as String,
      description: json['description'] as String,
      category: json['category'] as String?,
      bodySystem: json['body_system'] as String?,
      contentId: contentIdString,
      pageMarker: json['page_marker'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$MedicalCodeModelToJson(this);
}


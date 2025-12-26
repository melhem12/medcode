import '../../domain/entities/speciality.dart';

class SpecialityModel extends Speciality {
  SpecialityModel({
    required super.id,
    required super.name,
  });

  factory SpecialityModel.fromJson(Map<String, dynamic> json) {
    return SpecialityModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}



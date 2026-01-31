import '../../domain/entities/hospital.dart';

class HospitalModel extends Hospital {
  HospitalModel({
    required super.id,
    required super.name,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
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























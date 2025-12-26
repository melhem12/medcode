import 'package:json_annotation/json_annotation.dart';
import 'medical_code_model.dart';

part 'paginated_response_model.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponseModel<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedResponseModel({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginatedResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedResponseModelFromJson(json, fromJsonT);
}



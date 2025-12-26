import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_response.dart';
import 'user_model.dart';

// part 'auth_response_model.g.dart'; // Using manual serialization

@JsonSerializable(explicitToJson: true)
class AuthResponseModel extends AuthResponse {
  @override
  UserModel get user => super.user as UserModel;

  AuthResponseModel({
    required UserModel user,
    required super.token,
  }) : super(user: user);

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    print('AuthResponseModel.fromJson: $json');
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'token': token,
  };

  factory AuthResponseModel.fromEntity(AuthResponse response) {
    return AuthResponseModel(
      user: UserModel.fromEntity(response.user),
      token: response.token,
    );
  }
}


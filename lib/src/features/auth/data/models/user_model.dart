import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.userType,
    super.adminSubType,
    super.speciality,
    super.licenceNumber,
    super.hospitalId,
    super.avatarUrl,
    required super.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    final id = idVal is int ? idVal.toString() : (idVal?.toString() ?? '');
    final email = (json['email'] ?? '') as String;
    final name = (json['name'] as String?) ?? email;

    final userType = (json['user_type'] as String?) ??
        (json['userType'] as String?) ??
        'administrative';
    final adminSubType = (json['admin_sub_type'] as String?) ??
        (json['adminSubType'] as String?);

    final isAdminVal = json['is_admin'];
    final isAdmin = isAdminVal is bool
        ? isAdminVal
        : isAdminVal is num
            ? isAdminVal != 0
            : (isAdminVal?.toString().toLowerCase() == 'true' ||
                isAdminVal?.toString() == '1');

    return UserModel(
      id: id,
      email: email,
      name: name,
      userType: userType,
      adminSubType: adminSubType,
      speciality: json['speciality'] as String?,
      licenceNumber: json['licence_number'] as String?,
      hospitalId: json['hospital_id'] as int?,
      avatarUrl: json['avatar_url'] as String?,
      isAdmin: isAdmin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'user_type': userType,
      'admin_sub_type': adminSubType,
      'speciality': speciality,
      'licence_number': licenceNumber,
      'hospital_id': hospitalId,
      'avatar_url': avatarUrl,
      'is_admin': isAdmin,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      userType: user.userType,
      adminSubType: user.adminSubType,
      speciality: user.speciality,
      licenceNumber: user.licenceNumber,
      hospitalId: user.hospitalId,
      avatarUrl: user.avatarUrl,
      isAdmin: user.isAdmin,
    );
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String userType;
  final String? adminSubType;
  final String? speciality;
  final String? licenceNumber;
  final int? hospitalId;
  final String? avatarUrl;
  final bool isAdmin;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.adminSubType,
    this.speciality,
    this.licenceNumber,
    this.hospitalId,
    this.avatarUrl,
    required this.isAdmin,
  });
}





class UserTypeRules {
  static bool isAdmin(String userType, String? adminSubType) {
    return userType == 'admin' || userType == 'administrative' || userType == 'super_admin';
  }

  static bool isSuperAdmin(String userType, String? adminSubType) {
    // Backend uses user_type = 'super_admin' (not admin_sub_type)
    return userType == 'super_admin';
  }

  static Map<String, dynamic> buildRegistrationPayload({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? adminSubType,
    String? speciality,
    String? licenceNumber,
    int? hospitalId,
  }) {
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
      'user_type': userType,
    };

    if (userType == 'admin') {
      if (adminSubType == 'hospital') {
        if (hospitalId == null) {
          throw Exception('Hospital ID is required for hospital admin');
        }
        payload['admin_sub_type'] = adminSubType;
        payload['hospital_id'] = hospitalId;
        // Do NOT send speciality or licence_number for hospital admin
      } else if (adminSubType == 'physician') {
        if (speciality == null || speciality.isEmpty) {
          throw Exception('Speciality is required for physician admin');
        }
        if (licenceNumber == null || licenceNumber.isEmpty) {
          throw Exception('Licence number is required for physician admin');
        }
        payload['admin_sub_type'] = adminSubType;
        payload['speciality'] = speciality;
        payload['licence_number'] = licenceNumber;
        // Hospital is optional for physician admin
        if (hospitalId != null) {
          payload['hospital_id'] = hospitalId;
        }
      } else {
        throw Exception('Invalid admin sub type');
      }
    } else if (userType == 'resident') {
      // Residents don't need speciality, licence_number, or hospital
      // Just basic info
    }

    return payload;
  }
}


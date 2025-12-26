import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/utils/user_type_rules.dart';

enum AdminSection { contents, medicalCodes, importCodes, specialities, hospitals }

class AdminSuperBloc extends Cubit<AdminSection?> {
  AdminSuperBloc() : super(null);

  bool isAllowed(AuthState state, AdminSection section) {
    if (state is! AuthAuthenticated) return false;
    final user = state.user;
    // Super admin gets all, admin gets all admin sections too
    if (UserTypeRules.isSuperAdmin(user.userType, user.adminSubType)) return true;
    return UserTypeRules.isAdmin(user.userType, user.adminSubType);
  }
}

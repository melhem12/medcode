import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/user_type_selection_page.dart';
import '../../features/auth/presentation/pages/professional_information_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/admin_subtype_selection_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/contents/presentation/pages/contents_home_page.dart';
import '../../features/medical_codes/presentation/pages/medical_codes_list_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/user/presentation/pages/profile_page.dart';
import '../../features/admin/presentation/pages/admin_home_page.dart';
import '../../features/admin/presentation/pages/manage_contents_page.dart';
import '../../features/admin/presentation/pages/manage_medical_codes_page.dart';
import '../../features/admin/presentation/pages/manage_specialities_page.dart';
import '../../features/admin/presentation/pages/manage_hospitals_page.dart';
import '../../features/admin/presentation/cubit/admin_medical_code_crud_cubit.dart';
import '../../features/admin/presentation/cubit/admin_medical_codes_list_cubit.dart';
import '../../features/medical_codes/presentation/pages/admin_import_page.dart';
import '../../features/medical_codes/presentation/pages/admin_import_all_page.dart';
import '../../features/medical_codes/presentation/pages/medical_code_detail_page.dart';
import '../../features/user/presentation/pages/manage_offline_data_page.dart';
import '../../core/utils/user_type_rules.dart';
import '../../core/widgets/exit_confirmation_wrapper.dart';
import '../di/injection_container.dart' as di;

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/splash',
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/user-type-selection',
      builder: (context, state) => const UserTypeSelectionPage(),
    ),
    GoRoute(
      path: '/professional-information',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final userType = extra?['user_type'] as String? ?? 'resident';
        final adminSubtype = extra?['admin_subtype'] as String?;
        return ProfessionalInformationPage(
          userType: userType,
          adminSubtype: adminSubtype,
        );
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final userType = extra?['user_type'] as String? ?? 'resident';
        final adminSubtype = extra?['admin_subtype'] as String?;
        return RegisterPage(
          userType: userType,
          adminSubtype: adminSubtype,
        );
      },
    ),
    GoRoute(
      path: '/admin-subtype-selection',
      builder: (context, state) => const AdminSubtypeSelectionPage(),
    ),
    GoRoute(
      path: '/contents',
      builder: (context, state) => const ContentsHomePage(),
    ),
    GoRoute(
      path: '/medical-codes',
      builder: (context, state) {
        // Only wrap if not coming from home/subcategories (no contentId)
        final contentId = state.uri.queryParameters['contentId'];
        if (contentId == null || contentId.isEmpty) {
          return ExitConfirmationWrapper(
            child: const MedicalCodesListPage(),
          );
        }
        return const MedicalCodesListPage();
      },
    ),
    GoRoute(
      path: '/medical-codes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MedicalCodeDetailPage(codeId: id);
      },
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/admin/home',
      builder: (context, state) {
        // Check if user is admin or super_admin
        try {
          if (!GetIt.instance.isRegistered<AuthBloc>()) {
            return const ContentsHomePage();
          }
          
          final authState = GetIt.instance<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final isAdmin = UserTypeRules.isAdmin(
              authState.user.userType,
              authState.user.adminSubType,
            );
            final isSuperAdmin = UserTypeRules.isSuperAdmin(
              authState.user.userType,
              authState.user.adminSubType,
            );
            
            if (isAdmin || isSuperAdmin) {
              return const AdminHomePage();
            }
          }
          // Redirect to home if not admin
          return const ContentsHomePage();
        } catch (e) {
          return const ContentsHomePage();
        }
      },
    ),
    GoRoute(
      path: '/admin/contents',
      builder: (context, state) => const ManageContentsPage(),
    ),
    GoRoute(
      path: '/admin/medical-codes',
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider<AdminMedicalCodeCrudCubit>(
            create: (_) => di.sl<AdminMedicalCodeCrudCubit>(),
          ),
          BlocProvider<AdminMedicalCodesListCubit>(
            create: (_) => di.sl<AdminMedicalCodesListCubit>()..loadMedicalCodes(),
          ),
        ],
        child: const ManageMedicalCodesPage(),
      ),
    ),
    GoRoute(
      path: '/admin/specialities',
      builder: (context, state) => const ManageSpecialitiesPage(),
    ),
    GoRoute(
      path: '/admin/hospitals',
      builder: (context, state) => const ManageHospitalsPage(),
    ),
    GoRoute(
      path: '/admin/import',
      builder: (context, state) {
        final contentId = state.uri.queryParameters['contentId'];
        return AdminImportPage(contentId: contentId);
      },
    ),
    GoRoute(
      path: '/admin/import-all',
      builder: (context, state) => const AdminImportAllPage(),
    ),
    GoRoute(
      path: '/manage-offline-data',
      builder: (context, state) => const ManageOfflineDataPage(),
    ),
  ],
  redirect: (context, state) {
    try {
      // Always allow splash screen to show
      final isSplashRoute = state.matchedLocation == '/splash';
      if (isSplashRoute) {
        return null; // Allow splash to handle navigation
      }

      // Check if AuthBloc is registered before accessing it
      if (!GetIt.instance.isRegistered<AuthBloc>()) {
        return '/splash';
      }

      final authBloc = GetIt.instance<AuthBloc>();
      final authState = authBloc.state;
      
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/user-type-selection' ||
          state.matchedLocation == '/professional-information' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/admin-subtype-selection';

      // If initial state, don't redirect yet - let splash handle it
      if (authState is AuthInitial) {
        return null;
      }

      if (authState is AuthAuthenticated) {
        if (isLoginRoute) {
          return '/contents';
        }
        return null;
      } else {
        if (!isLoginRoute) {
          return '/login';
        }
        return null;
      }
    } catch (e) {
      // If error, allow splash to handle it
      if (state.matchedLocation == '/splash') {
        return null;
      }
      // Default to splash screen on error
      return '/splash';
    }
  },
  // refreshListenable: GoRouterRefreshStream(
  //   Stream.periodic(const Duration(milliseconds: 100))
  //       .asyncMap((_) => di.sl<AuthBloc>().stream),
  // ),
);

// class GoRouterRefreshStream extends ChangeNotifier {
//   GoRouterRefreshStream(Stream<dynamic> stream) {
//     _subscription = stream.listen((_) => notifyListeners());
//   }

//   late final StreamSubscription<dynamic> _subscription;

//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }
// }

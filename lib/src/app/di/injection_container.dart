import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/dio_client.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/medical_codes/data/datasources/medical_codes_remote_data_source.dart';
import '../../features/medical_codes/data/repositories/medical_codes_repository_impl.dart';
import '../../features/medical_codes/domain/repositories/medical_codes_repository.dart';
import '../../features/medical_codes/domain/usecases/get_medical_codes_usecase.dart';
import '../../features/medical_codes/domain/usecases/get_medical_code_by_id_usecase.dart';
import '../../features/medical_codes/domain/usecases/import_medical_codes_usecase.dart';
import '../../features/medical_codes/domain/usecases/manage_medical_codes_usecases.dart';
import '../../features/medical_codes/presentation/bloc/code_list_bloc.dart';
import '../../features/medical_codes/presentation/bloc/code_detail_bloc.dart';
import '../../features/medical_codes/presentation/cubit/admin_import_cubit.dart';
import '../../features/admin/presentation/cubit/admin_medical_codes_list_cubit.dart';
import '../../features/contents/data/datasources/contents_remote_data_source.dart';
import '../../features/contents/data/repositories/contents_repository_impl.dart';
import '../../features/contents/domain/repositories/contents_repository.dart';
import '../../features/contents/domain/usecases/get_contents_usecase.dart';
import '../../features/contents/domain/usecases/manage_contents_usecases.dart';
import '../../features/contents/presentation/cubit/contents_cubit.dart';
import '../../features/user/data/datasources/user_remote_data_source.dart';
import '../../features/user/data/repositories/user_repository_impl.dart';
import '../../features/user/domain/repositories/user_repository.dart';
import '../../features/user/domain/usecases/get_profile_usecase.dart';
import '../../features/user/domain/usecases/update_profile_usecase.dart';
import '../../features/user/domain/usecases/upload_avatar_usecase.dart';
import '../../features/user/presentation/bloc/user_bloc.dart';
import '../../features/user/data/datasources/offline_data_local_data_source.dart';
import '../../features/user/presentation/cubit/offline_data_cubit.dart';
import '../../features/user/presentation/cubit/theme_cubit.dart';
import '../../features/favorites/data/datasources/favorites_local_data_source.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/admin/presentation/cubit/admin_content_crud_cubit.dart';
import '../../features/admin/presentation/cubit/admin_medical_code_crud_cubit.dart';
import '../../features/admin/presentation/cubit/admin_speciality_hospital_cubit.dart';
import '../../features/admin/presentation/cubit/specialities_cubit.dart';
import '../../features/admin/presentation/cubit/hospitals_cubit.dart';
import '../../features/admin/data/sources/admin_speciality_hospital_remote_data_source.dart';
import '../../features/admin/domain/usecases/manage_specialities_hospitals_usecases.dart';
import '../../features/auth/data/datasources/specialities_remote_data_source.dart';
import '../../features/auth/data/datasources/hospitals_remote_data_source.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Core
  sl.registerLazySingleton(() => DioClient());

  // Auth - Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureStorage: const FlutterSecureStorage(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );
  sl.registerLazySingleton<SpecialitiesRemoteDataSource>(
    () => SpecialitiesRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<HospitalsRemoteDataSource>(
    () => HospitalsRemoteDataSourceImpl(sl<DioClient>()),
  );

  // Auth - Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      dioClient: sl<DioClient>(),
    ),
  );

  // Auth - Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl<AuthRepository>()));

  // Auth - Bloc
  sl.registerLazySingleton(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      checkAuthStatusUseCase: sl<CheckAuthStatusUseCase>(),
      favoritesCubit: sl<FavoritesCubit>(),
    ),
  );

  // Medical Codes - Data Sources
  sl.registerLazySingleton<MedicalCodesRemoteDataSource>(
    () => MedicalCodesRemoteDataSourceImpl(sl<DioClient>()),
  );

  // Medical Codes - Repository
  sl.registerLazySingleton<MedicalCodesRepository>(
    () => MedicalCodesRepositoryImpl(sl<MedicalCodesRemoteDataSource>()),
  );

  // Medical Codes - Use Cases
  sl.registerLazySingleton(
    () => GetMedicalCodesUseCase(sl<MedicalCodesRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMedicalCodeByIdUseCase(sl<MedicalCodesRepository>()),
  );
  sl.registerLazySingleton(
    () => ImportMedicalCodesUseCase(sl<MedicalCodesRepository>()),
  );
  sl.registerLazySingleton(
    () => ExportMedicalCodesUseCase(sl<MedicalCodesRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateMedicalCodeUseCase(sl<MedicalCodesRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateMedicalCodeUseCase(sl<MedicalCodesRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteMedicalCodeUseCase(sl<MedicalCodesRepository>()),
  );

  // Medical Codes - Bloc/Cubit
  sl.registerLazySingleton(
    () => CodeListBloc(getMedicalCodesUseCase: sl<GetMedicalCodesUseCase>()),
  );
  sl.registerLazySingleton(
    () => CodeDetailBloc(
      getMedicalCodeByIdUseCase: sl<GetMedicalCodeByIdUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => AdminImportCubit(
      importMedicalCodesUseCase: sl<ImportMedicalCodesUseCase>(),
    ),
  );

  // Contents - Data Sources
  sl.registerLazySingleton<ContentsRemoteDataSource>(
    () => ContentsRemoteDataSourceImpl(sl<DioClient>()),
  );

  // Contents - Repository
  sl.registerLazySingleton<ContentsRepository>(
    () => ContentsRepositoryImpl(sl<ContentsRemoteDataSource>()),
  );

  // Contents - Use Cases
  sl.registerLazySingleton(() => GetContentsUseCase(sl<ContentsRepository>()));
  sl.registerLazySingleton(
    () => ExportContentsUseCase(sl<ContentsRepository>()),
  );
  sl.registerLazySingleton(
    () => ImportContentsUseCase(sl<ContentsRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateContentUseCase(sl<ContentsRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateContentUseCase(sl<ContentsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteContentUseCase(sl<ContentsRepository>()),
  );

  // Contents - Cubit
  sl.registerLazySingleton(
    () => ContentsCubit(getContentsUseCase: sl<GetContentsUseCase>()),
  );

  // User - Data Sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<OfflineDataLocalDataSource>(
    () => OfflineDataLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  // User - Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl<UserRemoteDataSource>()),
  );

  // User - Use Cases
  sl.registerLazySingleton(() => GetProfileUseCase(sl<UserRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<UserRepository>()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl<UserRepository>()));

  // User - Bloc/Cubit
  sl.registerLazySingleton(
    () => UserBloc(
      getProfileUseCase: sl<GetProfileUseCase>(),
      updateProfileUseCase: sl<UpdateProfileUseCase>(),
      uploadAvatarUseCase: sl<UploadAvatarUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => OfflineDataCubit(
      localDataSource: sl<OfflineDataLocalDataSource>(),
    ),
  );
  sl.registerLazySingleton(() => ThemeCubit(sl<SharedPreferences>()));

  // Favorites - Data Sources
  sl.registerLazySingleton<FavoritesLocalDataSource>(
    () => FavoritesLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  // Favorites - Repository
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(sl<FavoritesLocalDataSource>()),
  );

  // Favorites - Cubit
  sl.registerLazySingleton(
    () => FavoritesCubit(
      favoritesRepository: sl<FavoritesRepository>(),
      medicalCodesRepository: sl<MedicalCodesRepository>(),
    ),
  );

  // Admin - Cubits
  // Note: ExportContentsUseCase and ImportContentsUseCase are already registered above
  sl.registerLazySingleton(
    () => AdminContentCrudCubit(
      exportUseCase: sl<ExportContentsUseCase>(),
      importUseCase: sl<ImportContentsUseCase>(),
      createUseCase: sl<CreateContentUseCase>(),
      updateUseCase: sl<UpdateContentUseCase>(),
      deleteUseCase: sl<DeleteContentUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => AdminMedicalCodeCrudCubit(
      exportUseCase: sl<ExportMedicalCodesUseCase>(),
      createUseCase: sl<CreateMedicalCodeUseCase>(),
      updateUseCase: sl<UpdateMedicalCodeUseCase>(),
      deleteUseCase: sl<DeleteMedicalCodeUseCase>(),
    ),
  );
  sl.registerFactory(
    () => AdminMedicalCodesListCubit(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton(
    () => AdminSpecialityHospitalRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton(() =>
      CreateSpecialityUseCase(sl<AdminSpecialityHospitalRemoteDataSource>()));
  sl.registerLazySingleton(() =>
      UpdateSpecialityUseCase(sl<AdminSpecialityHospitalRemoteDataSource>()));
  sl.registerLazySingleton(() =>
      DeleteSpecialityUseCase(sl<AdminSpecialityHospitalRemoteDataSource>()));
  sl.registerLazySingleton(() =>
      CreateHospitalUseCase(sl<AdminSpecialityHospitalRemoteDataSource>()));
  sl.registerLazySingleton(() =>
      UpdateHospitalUseCase(sl<AdminSpecialityHospitalRemoteDataSource>()));
  sl.registerLazySingleton(() =>
      DeleteHospitalUseCase(sl<AdminSpecialityHospitalRemoteDataSource>()));
  sl.registerLazySingleton(
    () => AdminSpecialityHospitalCubit(
      createSpeciality: sl<CreateSpecialityUseCase>(),
      updateSpeciality: sl<UpdateSpecialityUseCase>(),
      deleteSpeciality: sl<DeleteSpecialityUseCase>(),
      createHospital: sl<CreateHospitalUseCase>(),
      updateHospital: sl<UpdateHospitalUseCase>(),
      deleteHospital: sl<DeleteHospitalUseCase>(),
    ),
  );
  
  // Admin - Specialities & Hospitals Cubits
  sl.registerLazySingleton(
    () => SpecialitiesCubit(
      dataSource: sl<SpecialitiesRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton(
    () => HospitalsCubit(
      dataSource: sl<HospitalsRemoteDataSource>(),
    ),
  );
}

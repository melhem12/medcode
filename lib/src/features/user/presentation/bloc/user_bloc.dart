import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;

  UserBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadAvatarUseCase,
  }) : super(UserInitial()) {
    on<GetProfileEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadAvatarEvent>(_onUploadAvatar);
  }

  Future<void> _onGetProfile(
    GetProfileEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    final result = await getProfileUseCase();
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserLoaded(user)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    final result = await updateProfileUseCase(event.payload);
    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          emit(UserValidationError(failure.message, failure.fieldErrors));
        } else {
          emit(UserError(failure.message));
        }
      },
      (user) => emit(UserLoaded(user)),
    );
  }

  Future<void> _onUploadAvatar(
    UploadAvatarEvent event,
    Emitter<UserState> emit,
  ) async {
    final result = await uploadAvatarUseCase(event.filePath);
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (avatarUrl) {
        final currentState = state;
        if (currentState is UserLoaded) {
          // Update user with new avatar URL
          final updatedUser = User(
            id: currentState.user.id,
            email: currentState.user.email,
            name: currentState.user.name,
            userType: currentState.user.userType,
            adminSubType: currentState.user.adminSubType,
            speciality: currentState.user.speciality,
            licenceNumber: currentState.user.licenceNumber,
            hospitalId: currentState.user.hospitalId,
            avatarUrl: avatarUrl,
            isAdmin: currentState.user.isAdmin,
          );
          emit(UserLoaded(updatedUser));
        }
      },
    );
  }
}


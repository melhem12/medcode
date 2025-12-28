import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final FavoritesCubit favoritesCubit;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.favoritesCubit,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(event.email, event.password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (response) => emit(AuthAuthenticated(response.user)),
    );
  }

  Future<void> _onRegister(
      RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerUseCase(event.payload);
    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          emit(AuthValidationError(failure.message, failure.fieldErrors));
        } else {
          emit(AuthError(failure.message));
        }
      },
      (response) => emit(AuthAuthenticated(response.user)),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        favoritesCubit.clearFavorites();
        emit(AuthUnauthenticated());
      },
    );
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final result = await checkAuthStatusUseCase();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (user != null) {
          // User is authenticated with valid token and cached user data
          emit(AuthAuthenticated(user));
        } else {
          // No token or user cached, user needs to login
          emit(AuthUnauthenticated());
        }
      },
    );
  }
}

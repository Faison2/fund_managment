import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tsl/features/auth/login/bloc/state.dart';
import '../repository/repository.dart';
import 'event.dart';


class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository repository;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  LoginBloc({required this.repository}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoadSavedCredentials>(_onLoadSavedCredentials);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<ToggleRememberMe>(_onToggleRememberMe);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    if (event.username.trim().isEmpty || event.password.isEmpty) {
      emit(const LoginFailure(message: 'Please enter both email/phone number and password'));
      return;
    }

    emit(LoginLoading());

    try {
      final result = await repository.login(
        username: event.username.trim(),
        password: event.password,
      );

      if (result['success'] == true) {
        final cdsNumber = result['cdsNumber'] as String;
        final accountStatus = result['accountStatus'] as String;

        await repository.saveUserData(
          cdsNumber: cdsNumber,
          accountStatus: accountStatus,
          username: event.username.trim(),
          rememberMe: event.rememberMe,
        );

        if (cdsNumber.isEmpty) {
          emit(LoginNoCdsNumber(username: event.username.trim()));
        } else {
          emit(LoginSuccess(
            cdsNumber: cdsNumber,
            accountStatus: accountStatus,
            username: event.username.trim(),
          ));
        }
      } else {
        emit(LoginFailure(message: result['message'] as String));
      }
    } catch (e) {
      emit(LoginFailure(message: 'An unexpected error occurred'));
    }
  }

  Future<void> _onLoadSavedCredentials(LoadSavedCredentials event, Emitter<LoginState> emit) async {
    try {
      final credentials = await repository.loadSavedCredentials();
      _rememberMe = credentials['rememberMe'] as bool;

      emit(CredentialsLoaded(
        savedUsername: credentials['savedUsername'] as String?,
        rememberMe: _rememberMe,
      ));
    } catch (e) {
      emit(const CredentialsLoaded(rememberMe: false));
    }
  }

  void _onTogglePasswordVisibility(TogglePasswordVisibility event, Emitter<LoginState> emit) {
    _obscurePassword = !_obscurePassword;
    emit(PasswordVisibilityToggled(obscurePassword: _obscurePassword));
  }

  void _onToggleRememberMe(ToggleRememberMe event, Emitter<LoginState> emit) {
    _rememberMe = event.value;
    emit(RememberMeToggled(rememberMe: _rememberMe));
  }

  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
}

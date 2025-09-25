import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const LoginSubmitted({
    required this.username,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [username, password, rememberMe];
}

class LoadSavedCredentials extends LoginEvent {}

class TogglePasswordVisibility extends LoginEvent {}

class ToggleRememberMe extends LoginEvent {
  final bool value;

  const ToggleRememberMe(this.value);

  @override
  List<Object?> get props => [value];
}
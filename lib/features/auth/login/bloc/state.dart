import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String cdsNumber;
  final String accountStatus;
  final String username;

  const LoginSuccess({
    required this.cdsNumber,
    required this.accountStatus,
    required this.username,
  });

  @override
  List<Object?> get props => [cdsNumber, accountStatus, username];
}

class LoginNoCdsNumber extends LoginState {
  final String username;

  const LoginNoCdsNumber({required this.username});

  @override
  List<Object?> get props => [username];
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class CredentialsLoaded extends LoginState {
  final String? savedUsername;
  final bool rememberMe;

  const CredentialsLoaded({
    this.savedUsername,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [savedUsername, rememberMe];
}

class PasswordVisibilityToggled extends LoginState {
  final bool obscurePassword;

  const PasswordVisibilityToggled({required this.obscurePassword});

  @override
  List<Object?> get props => [obscurePassword];
}

class RememberMeToggled extends LoginState {
  final bool rememberMe;

  const RememberMeToggled({required this.rememberMe});

  @override
  List<Object?> get props => [rememberMe];
}

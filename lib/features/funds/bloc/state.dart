import 'package:equatable/equatable.dart';

import '../model/model.dart';

abstract class FundsState extends Equatable {
  const FundsState();

  @override
  List<Object> get props => [];
}

class FundsInitial extends FundsState {
  const FundsInitial();
}

class FundsLoading extends FundsState {
  const FundsLoading();
}

class FundsLoaded extends FundsState {
  final List<Fund> funds;

  const FundsLoaded(this.funds);

  @override
  List<Object> get props => [funds];
}

class FundsError extends FundsState {
  final String message;

  const FundsError(this.message);

  @override
  List<Object> get props => [message];
}
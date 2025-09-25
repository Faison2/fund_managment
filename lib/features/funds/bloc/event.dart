import 'package:equatable/equatable.dart';

abstract class FundsEvent extends Equatable {
  const FundsEvent();

  @override
  List<Object> get props => [];
}

class LoadFunds extends FundsEvent {
  const LoadFunds();
}

class RefreshFunds extends FundsEvent {
  const RefreshFunds();
}
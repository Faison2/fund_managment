import 'package:equatable/equatable.dart';
import '../model/model.dart'; // adjust path to wherever your Fund model lives

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

class SubscribeToFund extends FundsEvent {
  final Fund fund;
  const SubscribeToFund(this.fund);

  @override
  List<Object> get props => [fund];
}
import 'package:equatable/equatable.dart';
import '../model/model.dart';

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
  final String cdsNo;

  const SubscribeToFund({
    required this.fund,
    required this.cdsNo,
  });

  @override
  List<Object> get props => [fund, cdsNo];
}
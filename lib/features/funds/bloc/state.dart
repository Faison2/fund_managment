import 'package:equatable/equatable.dart';

import '../model/model.dart';
import '../model/sub_account.dart'; // add your SubAccount model here

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

// ── Subscription states ───────────────────────────────────────────────────────

class FundSubscribing extends FundsState {
  final String fundingCode; // identifies which card shows a spinner
  final List<Fund> funds;   // keeps the list rendered during the API call

  const FundSubscribing({required this.fundingCode, required this.funds});

  @override
  List<Object> get props => [fundingCode, funds];
}

class FundSubscribed extends FundsState {
  final SubAccount subAccount; // the newly created sub account from the API
  final List<Fund> funds;

  const FundSubscribed({required this.subAccount, required this.funds});

  @override
  List<Object> get props => [subAccount, funds];
}

class FundSubscriptionError extends FundsState {
  final String message;
  final List<Fund> funds; // keeps the list rendered so the user can retry

  const FundSubscriptionError({required this.message, required this.funds});

  @override
  List<Object> get props => [message, funds];
}
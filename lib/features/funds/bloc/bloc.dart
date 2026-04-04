import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tsl/features/funds/bloc/state.dart';

import '../model/model.dart';
import '../repository/repository.dart';
import 'event.dart';

class FundsBloc extends Bloc<FundsEvent, FundsState> {
  final FundsRepository fundsRepository;

  FundsBloc({required this.fundsRepository}) : super(const FundsInitial()) {
    on<LoadFunds>(_onLoadFunds);
    on<RefreshFunds>(_onRefreshFunds);
    on<SubscribeToFund>(_onSubscribeToFund); // ← new
  }

  Future<void> _onLoadFunds(LoadFunds event, Emitter<FundsState> emit) async {
    emit(const FundsLoading());

    try {
      final funds = await fundsRepository.fetchFunds();
      emit(FundsLoaded(funds));
    } catch (error) {
      emit(FundsError(error.toString()));
    }
  }

  Future<void> _onRefreshFunds(RefreshFunds event, Emitter<FundsState> emit) async {
    try {
      final funds = await fundsRepository.fetchFunds();
      emit(FundsLoaded(funds));
    } catch (error) {
      emit(FundsError(error.toString()));
    }
  }

  Future<void> _onSubscribeToFund(
      SubscribeToFund event,
      Emitter<FundsState> emit,
      ) async {
    // Grab the current fund list so the UI stays rendered throughout
    final currentFunds = switch (state) {
      FundsLoaded()           => (state as FundsLoaded).funds,
      FundSubscribed()        => (state as FundSubscribed).funds,
      FundSubscriptionError() => (state as FundSubscriptionError).funds,
      _                       => <Fund>[],
    };

    // Show spinner on the tapped card only
    emit(FundSubscribing(
      fundingCode: event.fund.fundingCode ?? '',
      funds: currentFunds,
    ));

    try {
      final subAccount = await fundsRepository.subscribeToFund(
        fundingCode: event.fund.fundingCode ?? '', authToken: '',
      );

      emit(FundSubscribed(subAccount: subAccount, funds: currentFunds));
    } catch (error) {
      emit(FundSubscriptionError(
        message: error.toString().replaceFirst('Exception: ', ''),
        funds: currentFunds,
      ));
    }
  }
}
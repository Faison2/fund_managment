import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tsl/features/funds/bloc/state.dart';

import '../repository/repository.dart';
import 'event.dart';

class FundsBloc extends Bloc<FundsEvent, FundsState> {
  final FundsRepository fundsRepository;

  FundsBloc({required this.fundsRepository}) : super(const FundsInitial()) {
    on<LoadFunds>(_onLoadFunds);
    on<RefreshFunds>(_onRefreshFunds);
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
}
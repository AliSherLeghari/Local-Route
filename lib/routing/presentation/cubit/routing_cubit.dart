import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/routing_repository.dart';
import 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  RoutingCubit({required this.repository}) : super(const RoutingState());

  // Routing operations will use this boundary starting in Phase 2.
  final RoutingRepository repository;

  void markMapReady() {
    if (!state.isMapReady) {
      emit(const RoutingState(isMapReady: true));
    }
  }
}

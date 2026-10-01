import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'routing/presentation/cubit/routing_cubit.dart';
import 'routing/presentation/screens/map_screen.dart';
import 'routing/repository/routing_repository.dart';
import 'routing/services/routing_service.dart';

class LocalRouteApp extends StatelessWidget {
  const LocalRouteApp({super.key, this.tileProvider});

  // Tests can supply local tiles without contacting the public tile server.
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoutingCubit(
        repository: const RoutingRepository(service: RoutingService()),
      ),
      child: MaterialApp(
        title: 'Local Route',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: MapScreen(tileProvider: tileProvider),
      ),
    );
  }
}

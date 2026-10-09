import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'routing/presentation/cubit/routing_cubit.dart';
import 'routing/presentation/screens/map_screen.dart';
import 'routing/repository/routing_repository.dart';
import 'routing/services/routing_service.dart';

class LocalRouteApp extends StatefulWidget {
  const LocalRouteApp({super.key, this.tileProvider, this.repository});

  // Tests inject local tiles and controlled routing without external traffic.
  final TileProvider? tileProvider;
  final RoutingRepository? repository;

  @override
  State<LocalRouteApp> createState() => _LocalRouteAppState();
}

class _LocalRouteAppState extends State<LocalRouteApp> {
  http.Client? _client;
  late final RoutingRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        RoutingRepository(
          service: RoutingService(
            client: _client = http.Client(),
            apiKey: const String.fromEnvironment('GRAPHHOPPER_API_KEY'),
          ),
        );
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoutingCubit(repository: _repository),
      child: MaterialApp(
        title: 'Local Route',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: MapScreen(tileProvider: widget.tileProvider),
      ),
    );
  }
}

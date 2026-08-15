import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/tasks/task_repository.dart';
import 'bloc/bloc_task_panel.dart';
import 'provider/provider_task_panel.dart';
import 'riverpod/riverpod_task_controller.dart';
import 'riverpod/riverpod_task_panel.dart';

class StatePatternsApp extends StatelessWidget {
  const StatePatternsApp({super.key, required this.repository});

  final TaskRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff155eef)),
      useMaterial3: true,
    ),
    home: DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('State Management Comparison'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Provider'),
              Tab(text: 'Riverpod'),
              Tab(text: 'Cubit'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProviderTaskPanel(repository: repository),
            ProviderScope(
              overrides: [taskRepositoryProvider.overrideWithValue(repository)],
              child: const RiverpodTaskPanel(),
            ),
            BlocTaskPanel(repository: repository),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/tasks/task_repository.dart';
import 'features/tasks/task_screen.dart';
import 'features/tasks/task_store.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5080',
  );
  final repository = RemoteTaskRepository(ApiClient(baseUrl: baseUrl));
  runApp(WmsLabApp(store: TaskStore(repository)));
}

class WmsLabApp extends StatelessWidget {
  const WmsLabApp({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter + .NET WMS Lab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff155eef)),
      useMaterial3: true,
    ),
    home: TaskScreen(store: store),
  );
}

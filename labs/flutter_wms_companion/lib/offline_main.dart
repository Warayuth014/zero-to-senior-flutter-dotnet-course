import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/tasks/task_repository.dart';
import 'features/tasks/task_store.dart';
import 'offline/offline_app.dart';
import 'offline/offline_database.dart';
import 'offline/offline_task_repository.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5080',
  );
  final database = OfflineDatabase.defaults();
  final repository = OfflineTaskRepository(
    remote: RemoteTaskRepository(ApiClient(baseUrl: baseUrl)),
    database: database,
  );
  runApp(
    OfflineWmsApp(
      database: database,
      repository: repository,
      store: TaskStore(repository),
    ),
  );
}

import 'package:flutter/widgets.dart';

import 'core/api_client.dart';
import 'features/tasks/task_repository.dart';
import 'state_patterns/state_patterns_app.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5080',
  );
  final repository = RemoteTaskRepository(ApiClient(baseUrl: baseUrl));
  runApp(StatePatternsApp(repository: repository));
}

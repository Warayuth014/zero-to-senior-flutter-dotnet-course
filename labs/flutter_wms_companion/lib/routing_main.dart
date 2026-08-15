import 'package:flutter/widgets.dart';

import 'core/api_client.dart';
import 'features/tasks/task_repository.dart';
import 'routing/routing_app.dart';
import 'routing/routing_session.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5080',
  );
  const authenticated = bool.fromEnvironment(
    'ROUTING_AUTHENTICATED',
    defaultValue: false,
  );
  final repository = RemoteTaskRepository(ApiClient(baseUrl: baseUrl));
  runApp(
    RoutingLabApp(
      session: RoutingSession(authenticated: authenticated),
      repository: repository,
    ),
  );
}

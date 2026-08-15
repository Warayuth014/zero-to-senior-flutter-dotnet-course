import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/tasks/task_repository.dart';
import 'routing_pages.dart';
import 'routing_session.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'routing-root');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home-branch');
final _taskNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'task-branch');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'settings-branch',
);

GoRouter createRoutingLabRouter({
  required RoutingSession session,
  required TaskRepository repository,
  String initialLocation = '/home',
}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: initialLocation,
  refreshListenable: session,
  redirect: (context, state) {
    final onLogin = state.matchedLocation == '/login';
    if (!session.authenticated) {
      if (onLogin) return null;
      return Uri(
        path: '/login',
        queryParameters: {'from': state.uri.toString()},
      ).toString();
    }
    if (onLogin) {
      return safeLocalLocation(state.uri.queryParameters['from']) ?? '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/home'),
    GoRoute(
      path: '/login',
      name: 'login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RoutingLoginPage(
        session: session,
        from: safeLocalLocation(state.uri.queryParameters['from']),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          RoutingShell(navigationShell: navigationShell, session: session),
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (_, _) => const RoutingHomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _taskNavigatorKey,
          routes: [
            GoRoute(
              path: '/tasks',
              name: 'tasks',
              builder: (context, state) => RoutingTaskListPage(
                repository: repository,
                statusFilter: state.uri.queryParameters['status'],
              ),
              routes: [
                GoRoute(
                  path: ':taskId',
                  name: 'taskDetail',
                  builder: (context, state) => RoutingTaskDetailPage(
                    taskId: state.pathParameters['taskId']!,
                    source: state.uri.queryParameters['source'],
                  ),
                  routes: [
                    GoRoute(
                      path: 'scan',
                      name: 'taskScan',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => RoutingScannerPage(
                        taskId: state.pathParameters['taskId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (_, _) => RoutingSettingsPage(session: session),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      RoutingNotFoundPage(uri: state.uri, error: state.error),
);

String? safeLocalLocation(String? candidate) {
  if (candidate == null || candidate.isEmpty) return null;
  final uri = Uri.tryParse(candidate);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (!candidate.startsWith('/') || candidate.startsWith('//')) return null;
  if (uri.path == '/login') return null;
  return uri.toString();
}

class RoutingLabApp extends StatefulWidget {
  const RoutingLabApp({
    super.key,
    required this.session,
    required this.repository,
    this.initialLocation = '/home',
  });

  final RoutingSession session;
  final TaskRepository repository;
  final String initialLocation;

  @override
  State<RoutingLabApp> createState() => _RoutingLabAppState();
}

class _RoutingLabAppState extends State<RoutingLabApp> {
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    router = createRoutingLabRouter(
      session: widget.session,
      repository: widget.repository,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'go_router Mobile WMS Lab',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff155eef)),
      useMaterial3: true,
    ),
    routerConfig: router,
  );
}

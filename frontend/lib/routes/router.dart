import 'package:flutter/material.dart';
import 'routes.dart';
import '../screens/tasks_list_screen.dart';

class AppRouter {
  const AppRouter();

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.tasks:
        return MaterialPageRoute<void>(
          builder: (_) => const TaskListScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (_) => const UnknownRouteScreen(),
          settings: settings,
        );
    }
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Route not found')));
  }
}

import 'package:{{project_name.snakeCase()}}/app/app.dart';
import 'package:{{project_name.snakeCase()}}/routing/routing.dart';{{#use_auto_route_router}}import 'package:auto_route/auto_route.dart';{{/use_auto_route_router}}import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';{{#use_go_router_router}}import 'package:go_router/go_router.dart';{{/use_go_router_router}}void main() {
{{#use_auto_route_router}}testWidgets(
    '''

GIVEN a routed app
├─ THAT starts with the new task path
WHEN the app starts
THEN the new task screen should be shown
''',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(
            routerConfig: AppRouter().config(
              deepLinkBuilder: (_) => const DeepLink.path('/tasks/new'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tasksScreenFinder = find.byType(NewTaskScreen);
      expect(tasksScreenFinder, findsOneWidget);
    },
  );{{/use_auto_route_router}}{{#use_go_router_router}}testWidgets(
    '''

GIVEN a routed app
├─ THAT starts with the new task path
WHEN the app starts
THEN the new task screen should be shown
''',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(
            routerConfig: GoRouter(
              routes: $appRoutes,
              initialLocation: '/tasks/new',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tasksScreenFinder = find.byType(NewTaskScreen);
      expect(tasksScreenFinder, findsOneWidget);
    },
  );{{/use_go_router_router}}
}

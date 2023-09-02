import 'package:{{project_name.snakeCase()}}/app/app.dart';
import 'package:{{project_name.snakeCase()}}/routing/routing.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
{{#use_auto_route_router}}testWidgets(
    '''

GIVEN a routed app
├─ THAT starts with the home path
WHEN the app starts
THEN the home screen should be shown
''',
    (tester) async {
      await tester.pumpWidget(
        MyApp(
          routerConfig: AppRouter().config(
            // ignore: use_named_constants
            deepLinkBuilder: (_) => const DeepLink.path('/'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
    },
  );{{/use_auto_route_router}}{{#use_go_router_router}}testWidgets(
    '''

GIVEN a routed app
├─ THAT starts with the home path
WHEN the app starts
THEN the home screen should be shown
''',
    (tester) async {
      await tester.pumpWidget(
        MyApp(
          routerConfig: GoRouter(
            routes: $appRoutes,
            initialLocation: '/',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final homeScreenFinder = find.byType(HomeScreen);
      expect(homeScreenFinder, findsOneWidget);
    },
  );{{/use_go_router_router}}}

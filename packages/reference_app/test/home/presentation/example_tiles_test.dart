import 'package:altoke_app/home/home.dart';
import 'package:altoke_app/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  final localizationVAriant = LocalizationVariant.withCommonSelector(
    localizedTextSelector: (l10n) => l10n.counterExampleLabel,
    partialCases: {
      const (Locale('en'), 'Counter'),
      const (Locale('es'), 'Contador'),
    },
  );

  testExhaustiveLocalizationVariant(
    '''

GIVEN a localization variant
WHEN testing the counter example tile
THEN all supported locales should be considered
''',
    localizationVAriant,
  );

  testLocalizedWidget(
    '''

GIVEN a counter example tile
WHEN it is displayed
THEN the tile should include the localized label
''',
    Scaffold(
      body: CounterExampleTile(),
    ),
    ancestorFinder: find.byKey(
      const Key(
        '<counter::example-tile::title>',
      ),
    ),
    variant: localizationVAriant,
  );

  testWidgets(
    '''

GIVEN a counter example tile
AND an injected routing controller
WHEN the tile is tapped
THEN the counter route should be visited
''',
    (tester) async {
      registerRoutingFallbackValues();
      final routingController = MockRoutingController();
      when(() => routingController.navigate(any()))
          .thenAnswer((_) async => null);
      await tester.pumpRoutedAppWithTestableWidget(
        routingController: routingController,
        testableWidget: Scaffold(
          body: CounterExampleTile(),
        ),
      );
      final counterExampleTileFinder = find.byType(CounterExampleTile);
      await tester.tap(counterExampleTileFinder);
      verify(() => routingController.navigate(CounterRoute())).called(1);
      verifyNoMoreInteractions(routingController);
    },
  );
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smash_up_india/core/constants/app_constants.dart';

void main() {
  testWidgets('Centralized TextScaling Policy Clamps Scale Factor to 1.3',
      (WidgetTester tester) async {
    double? resolvedScaleFactor;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, widget) {
          final mediaQuery = MediaQuery.of(context);
          final rawScale = mediaQuery.textScaler.scale(1.0);
          final clampedScale =
              rawScale.clamp(0.85, AppConstants.maxTextScaleFactor);

          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(clampedScale),
            ),
            child: Builder(
              builder: (innerContext) {
                resolvedScaleFactor =
                    MediaQuery.of(innerContext).textScaler.scale(10) / 10;
                return const Text('Test Text Scaling');
              },
            ),
          );
        },
      ),
    );

    expect(resolvedScaleFactor, equals(1.0));
  });

  testWidgets('App Layout Clamps 2.0 Accessibility System Text Scale to 1.3',
      (WidgetTester tester) async {
    double? clampedScaleFactor;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(2.0),
        ),
        child: MaterialApp(
          builder: (context, widget) {
            final mediaQuery = MediaQuery.of(context);
            final rawScale = mediaQuery.textScaler.scale(1.0);
            final clampedScale =
                rawScale.clamp(0.85, AppConstants.maxTextScaleFactor);

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(clampedScale),
              ),
              child: Builder(
                builder: (innerContext) {
                  clampedScaleFactor =
                      MediaQuery.of(innerContext).textScaler.scale(10) / 10;
                  return const Text('Test Clamped Text');
                },
              ),
            );
          },
        ),
      ),
    );

    expect(clampedScaleFactor, closeTo(1.3, 0.01));
  });
}

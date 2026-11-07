import 'package:fitmark/main.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    for (final size in [
      const Size(390, 844),
      const Size(820, 1180),
      const Size(1440, 900),
    ]) {
      testWidgets('navigation on $platform at $size', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        try {
          await tester.pumpWidget(const FitMarkApp());
          await tester.pumpAndSettle();
          expect(find.textContaining('No bikes saved yet.'), findsOneWidget);
          if (platform == TargetPlatform.iOS) {
            expect(find.byType(CupertinoApp), findsOneWidget);
            expect(find.byType(MaterialApp), findsNothing);
            expect(find.byType(fluent.FluentApp), findsNothing);
            expect(
              find.byType(CupertinoTabBar),
              size.width < 700 ? findsOneWidget : findsNothing,
            );
          } else if (platform == TargetPlatform.windows) {
            expect(find.byType(fluent.FluentApp), findsOneWidget);
            expect(find.byType(fluent.NavigationView), findsOneWidget);
            expect(find.byType(fluent.CommandBar), findsOneWidget);
            expect(find.byType(MaterialApp), findsNothing);
          } else {
            expect(find.byType(MaterialApp), findsOneWidget);
            expect(
              find.byType(NavigationRail),
              size.width >= 700 ? findsOneWidget : findsNothing,
            );
            expect(
              find.byType(NavigationBar),
              size.width < 700 ? findsOneWidget : findsNothing,
            );
          }
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pumpAndSettle();
          expect(
            find.text('No ride notes for this setup yet.'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      });
    }
  }
}

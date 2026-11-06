import 'package:fitmark/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('Fit Mark starts on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await tester.pumpWidget(const FitMarkApp());
        expect(find.text('No ride notes for this setup yet.'), findsOneWidget);
        if (platform == TargetPlatform.iOS) {
          expect(find.byType(CupertinoApp), findsOneWidget);
          expect(find.byType(MaterialApp), findsNothing);
        } else {
          expect(find.byType(MaterialApp), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}

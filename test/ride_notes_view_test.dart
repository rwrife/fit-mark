import 'package:fitmark/ride_notes.dart';
import 'package:fitmark/ride_notes_view.dart';
import 'package:fitmark/snapshots.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
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
    testWidgets('ride notes list and editor on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.physicalSize = const Size(900, 1100);
      tester.view.devicePixelRatio = 1;
      try {
        final snapshot = SetupSnapshot(
          id: 's1',
          takenAt: DateTime.utc(2026, 11, 1),
          measurements: {},
        );
        final journal = RideJournal(
          histories: {
            'bike': SnapshotHistory([snapshot]),
          },
        );
        final added = <RideNote>[];
        final view = RideNotesView(
          journal: journal,
          bikeId: 'bike',
          snapshotId: 's1',
          onAdd: added.add,
        );
        await tester.pumpWidget(
          platform == TargetPlatform.iOS
              ? CupertinoApp(
                  home: CupertinoPageScaffold(child: SafeArea(child: view)),
                )
              : platform == TargetPlatform.windows
              ? fluent.FluentApp(
                  home: fluent.NavigationView(
                    content: fluent.ScaffoldPage(content: view),
                  ),
                )
              : MaterialApp(home: Scaffold(body: view)),
        );
        expect(find.text('No ride notes for this setup yet.'), findsOneWidget);
        await tester.tap(find.text('Add ride note'));
        await tester.pumpAndSettle();
        expect(find.text('New ride note'), findsOneWidget);
        expect(
          find.text('Your own impressions, not a fit recommendation.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(added, isEmpty);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  }
}

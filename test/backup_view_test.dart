import 'dart:io';

import 'package:fitmark/backup_view.dart';
import 'package:fitmark/domain.dart';
import 'package:fitmark/local_store.dart';
import 'package:fitmark/snapshots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late LocalStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_view_test_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox<String>('backup_box');
    store = LocalStore(box);
    await store.save(
      FitMarkData(
        bikes: {
          'b-1': Bike(
            name: 'Aeroad',
            make: 'Canyon',
            model: 'CFR',
            type: 'Road',
          ),
        },
        histories: {'b-1': SnapshotHistory([])},
      ),
    );
  });

  tearDown(() async {
    await store.close();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  testWidgets('renders backup actions and warning copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BackupView(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local backup'), findsOneWidget);
    expect(
      find.textContaining('Files you export may contain personal ride notes.'),
      findsOneWidget,
    );
    expect(find.text('Export JSON backup'), findsOneWidget);
    expect(find.text('Export setup sheet'), findsOneWidget);
    expect(find.text('Preview JSON import'), findsOneWidget);
  });
}

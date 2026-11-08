import 'dart:io';

import 'package:fitmark/domain.dart';
import 'package:fitmark/local_store.dart';
import 'package:fitmark/ride_notes.dart';
import 'package:fitmark/snapshots.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fitmark_test_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox<String>('test_box');
    store = LocalStore(box);
  });

  tearDown(() async {
    await store.close();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('round-trip serialization preserves all fields', () {
    final bike = Bike(
      name: 'Endurace',
      make: 'Canyon',
      model: 'CF 7',
      type: 'Road',
      notes: 'Winter setup',
      points: [
        MeasurementPoint(
          id: 'saddle_height',
          label: 'Saddle Height',
          referenceMethod: 'BB center to saddle top along seat tube',
          unit: MeasurementUnit.mm,
          value: 745.0,
        ),
      ],
    );
    final snapshot = SetupSnapshot(
      id: 'snap-1',
      takenAt: DateTime.utc(2026, 3, 1, 10, 0),
      componentChanges: 'Raised saddle 5mm',
      measurements: {
        'saddle_height': MeasurementPoint(
          id: 'saddle_height',
          label: 'Saddle Height',
          referenceMethod: 'BB center to saddle top along seat tube',
          unit: MeasurementUnit.mm,
          value: 745.0,
        ),
      },
    );
    final note = RideNote(
      id: 'ride-1',
      bikeId: 'bike-1',
      snapshotId: 'snap-1',
      riddenAt: DateTime.utc(2026, 3, 2, 8, 30),
      durationMinutes: 90,
      distanceKm: 45.5,
      comfort: 4,
      terrain: 'Paved rolling hills',
      impressions: 'No knee pain, good power transfer',
    );
    final data = FitMarkData(
      bikes: {'bike-1': bike},
      histories: {
        'bike-1': SnapshotHistory([snapshot]),
      },
      notes: [note],
    );

    final jsonText = data.exportJson();
    final restored = FitMarkData.importJson(jsonText);

    expect(restored.bikes.length, 1);
    expect(restored.bikes['bike-1']!.name, 'Endurace');
    expect(restored.histories['bike-1']!.snapshots.first.id, 'snap-1');
    expect(
      restored.notes.first.impressions,
      'No knee pain, good power transfer',
    );
    expect(restored.setupSheet('bike-1'), contains('Endurace'));
    expect(restored.setupSheet('bike-1'), contains('745.0 mm'));
  });

  test('import validates schema version and rejects unsupported schema', () {
    expect(
      () => FitMarkData.importJson(
        '{"schemaVersion": 2, "bikes": [], "histories": {}, "notes": []}',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => FitMarkData.importJson('not-json'),
      throwsA(isA<FormatException>()),
    );
  });

  test('local store persists and recovers state across instances', () async {
    final bike = Bike(
      name: 'Gravel',
      make: 'Trek',
      model: 'Checkpoint',
      type: 'Gravel',
    );
    final initial = FitMarkData(
      bikes: {'g-1': bike},
      histories: {'g-1': SnapshotHistory([])},
      notes: [],
    );
    await store.save(initial);

    final loaded = store.load();
    expect(loaded.bikes.containsKey('g-1'), isTrue);
    expect(loaded.bikes['g-1']!.name, 'Gravel');
  });

  test('setup sheet formats empty snapshot cleanly', () {
    final bike = Bike(name: 'Track', make: '', model: '', type: 'Track');
    final data = FitMarkData(
      bikes: {'t-1': bike},
      histories: {'t-1': SnapshotHistory([])},
      notes: [],
    );
    final sheet = data.setupSheet('t-1');
    expect(sheet, contains('No setup snapshots recorded.'));
  });
}

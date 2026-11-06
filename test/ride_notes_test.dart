import 'dart:convert';

import 'package:fitmark/domain.dart';
import 'package:fitmark/ride_notes.dart';
import 'package:fitmark/snapshots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.parse('2026-11-01T08:00:00Z');
  final t1 = DateTime.parse('2026-11-02T08:00:00Z');

  SetupSnapshot makeSnapshot(String id) => SetupSnapshot(
    id: id,
    takenAt: t0,
    measurements: {
      'saddle': MeasurementPoint(
        id: 'saddle',
        label: 'Saddle height',
        referenceMethod: 'BB center to saddle top',
        unit: MeasurementUnit.mm,
        value: 740,
      ),
    },
  );

  RideJournal makeJournal() => RideJournal(
    histories: {
      'bike-1': SnapshotHistory([
        makeSnapshot('snap-1'),
        makeSnapshot('snap-2'),
      ]),
      'bike-2': SnapshotHistory([makeSnapshot('snap-a')]),
    },
  );

  test('valid note serializes to and from JSON', () {
    final note = RideNote(
      id: 'rn-1',
      bikeId: 'bike-1',
      snapshotId: 'snap-1',
      riddenAt: t0,
      durationMinutes: 75,
      distanceKm: 34.2,
      comfort: 4,
      terrain: 'Paved rolling hills',
      impressions: 'No lower back tightness; saddle feels well-supported.',
    );

    final roundTrip = RideNote.fromJson(jsonDecode(jsonEncode(note.toJson())));
    expect(roundTrip.id, 'rn-1');
    expect(roundTrip.bikeId, 'bike-1');
    expect(roundTrip.snapshotId, 'snap-1');
    expect(roundTrip.riddenAt, t0);
    expect(roundTrip.durationMinutes, 75);
    expect(roundTrip.distanceKm, 34.2);
    expect(roundTrip.comfort, 4);
    expect(roundTrip.terrain, 'Paved rolling hills');
    expect(
      roundTrip.impressions,
      'No lower back tightness; saddle feels well-supported.',
    );
  });

  test('validation enforces boundary constraints and non-empty notes', () {
    expect(
      () => RideNote(
        id: 'rn-1',
        bikeId: 'bike-1',
        snapshotId: 'snap-1',
        riddenAt: t0,
        comfort: 0,
        terrain: 'Road',
        impressions: 'Too low',
      ),
      throwsFormatException,
    );
    expect(
      () => RideNote(
        id: 'rn-1',
        bikeId: 'bike-1',
        snapshotId: 'snap-1',
        riddenAt: t0,
        comfort: 6,
        terrain: 'Road',
        impressions: 'Too high',
      ),
      throwsFormatException,
    );
    expect(
      () => RideNote(
        id: 'rn-1',
        bikeId: 'bike-1',
        snapshotId: 'snap-1',
        riddenAt: t0,
        comfort: 3,
        durationMinutes: -10,
        terrain: 'Road',
        impressions: 'Negative duration',
      ),
      throwsFormatException,
    );
    expect(
      () => RideNote(
        id: 'rn-1',
        bikeId: 'bike-1',
        snapshotId: 'snap-1',
        riddenAt: t0,
        comfort: 3,
        distanceKm: -5.0,
        terrain: 'Road',
        impressions: 'Negative distance',
      ),
      throwsFormatException,
    );
    expect(
      () => RideNote(
        id: 'rn-1',
        bikeId: 'bike-1',
        snapshotId: 'snap-1',
        riddenAt: t0,
        comfort: 3,
        terrain: 'Road',
        impressions: '   ',
      ),
      throwsFormatException,
    );
    expect(
      () => RideNote(
        id: ' rn-1 ',
        bikeId: 'bike-1',
        snapshotId: 'snap-1',
        riddenAt: t0,
        comfort: 3,
        terrain: 'Road',
        impressions: 'Trimmed check',
      ),
      throwsFormatException,
    );
  });

  test('journal rejects unknown bikes and detached snapshots', () {
    final journal = makeJournal();
    expect(
      () => journal.add(
        RideNote(
          id: 'n1',
          bikeId: 'bike-missing',
          snapshotId: 'snap-1',
          riddenAt: t0,
          comfort: 3,
          terrain: 'Gravel',
          impressions: 'Bike not registered',
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => journal.add(
        RideNote(
          id: 'n2',
          bikeId: 'bike-1',
          snapshotId: 'snap-missing',
          riddenAt: t0,
          comfort: 3,
          terrain: 'Gravel',
          impressions: 'Snapshot missing',
        ),
      ),
      throwsFormatException,
    );
  });

  test('journal groups and sorts notes chronologically descending', () {
    final journal = makeJournal()
        .add(
          RideNote(
            id: 'n1',
            bikeId: 'bike-1',
            snapshotId: 'snap-1',
            riddenAt: t0,
            comfort: 4,
            terrain: 'Road',
            impressions: 'Day 1 setup',
          ),
        )
        .add(
          RideNote(
            id: 'n2',
            bikeId: 'bike-1',
            snapshotId: 'snap-2',
            riddenAt: t1,
            comfort: 2,
            terrain: 'Road',
            impressions: 'Day 2 setup after saddle push forward',
          ),
        )
        .add(
          RideNote(
            id: 'n3',
            bikeId: 'bike-2',
            snapshotId: 'snap-a',
            riddenAt: t1,
            comfort: 5,
            terrain: 'Commute',
            impressions: 'City bike unchanged',
          ),
        );

    final bike1All = journal.forBike('bike-1');
    expect(bike1All.length, 2);
    expect(bike1All.first.id, 'n2');
    expect(bike1All.last.id, 'n1');

    final bike1Snap1 = journal.forBike('bike-1', snapshotId: 'snap-1');
    expect(bike1Snap1.length, 1);
    expect(bike1Snap1.single.id, 'n1');

    final bike2Notes = journal.forBike('bike-2');
    expect(bike2Notes.length, 1);
    expect(bike2Notes.single.id, 'n3');
  });
}

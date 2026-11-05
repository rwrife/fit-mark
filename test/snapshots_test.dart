import 'dart:convert';

import 'package:fitmark/domain.dart';
import 'package:fitmark/snapshots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.parse('2026-11-01T10:00:00Z');
  final t1 = DateTime.parse('2026-11-02T10:00:00Z');

  SetupSnapshot makeSnapshot(
    String id,
    DateTime time,
    Map<String, MeasurementPoint> points, {
    String notes = '',
    String? source,
  }) {
    return SetupSnapshot(
      id: id,
      takenAt: time,
      componentChanges: notes,
      sourceSnapshotId: source,
      measurements: points,
    );
  }

  test('snapshot roundtrips JSON immutably', () {
    final s = makeSnapshot('s1', t0, {
      'saddle': MeasurementPoint(
        id: 'saddle',
        label: 'Saddle height',
        referenceMethod: 'BB to top center',
        unit: MeasurementUnit.mm,
        value: 742,
      ),
    }, notes: 'New saddle installed');

    final json = s.toJson();
    final restored = SetupSnapshot.fromJson(jsonDecode(jsonEncode(json)));
    expect(restored.id, 's1');
    expect(restored.takenAt, t0);
    expect(restored.componentChanges, 'New saddle installed');
    expect(restored.measurements['saddle']!.value, 742);
    expect(
      () => restored.measurements['saddle'] = restored.measurements['saddle']!,
      throwsUnsupportedError,
    );
  });

  test('identical and signed deltas calculate exactly', () {
    final s1 = makeSnapshot('s1', t0, {
      'saddle': MeasurementPoint(
        id: 'saddle',
        label: 'Saddle height',
        referenceMethod: 'BB to top center',
        unit: MeasurementUnit.mm,
        value: 740,
      ),
      'angle': MeasurementPoint(
        id: 'angle',
        label: 'Saddle angle',
        referenceMethod: 'Level nose-to-tail',
        unit: MeasurementUnit.deg,
        value: -1.0,
      ),
    });

    final s2 = makeSnapshot('s2', t1, {
      'saddle': MeasurementPoint(
        id: 'saddle',
        label: 'Saddle height',
        referenceMethod: 'BB to top center',
        unit: MeasurementUnit.mm,
        value: 745,
      ),
      'angle': MeasurementPoint(
        id: 'angle',
        label: 'Saddle angle',
        referenceMethod: 'Level nose-to-tail',
        unit: MeasurementUnit.deg,
        value: -3.0,
      ),
    });

    final forward = compareSnapshots(s1, s2);
    expect(forward['saddle']!.status, ComparisonStatus.comparable);
    expect(forward['saddle']!.delta, 5.0);
    expect(forward['saddle']!.display, '+5 mm');

    expect(forward['angle']!.status, ComparisonStatus.comparable);
    expect(forward['angle']!.delta, -2.0);
    expect(forward['angle']!.display, '-2 deg');

    final reverse = compareSnapshots(s2, s1);
    expect(reverse['saddle']!.delta, -5.0);
    expect(reverse['saddle']!.display, '-5 mm');
    expect(reverse['angle']!.delta, 2.0);
    expect(reverse['angle']!.display, '+2 deg');

    final identical = compareSnapshots(s1, s1);
    expect(identical['saddle']!.delta, 0.0);
    expect(identical['saddle']!.display, '+0 mm');
  });

  test('mismatched reference methods refuse to emit signed deltas', () {
    final s1 = makeSnapshot('s1', t0, {
      'saddle': MeasurementPoint(
        id: 'saddle',
        label: 'Saddle height',
        referenceMethod: 'BB to top center',
        unit: MeasurementUnit.mm,
        value: 740,
      ),
    });
    final s2 = makeSnapshot('s2', t1, {
      'saddle': MeasurementPoint(
        id: 'saddle',
        label: 'Saddle height',
        referenceMethod: 'BB to saddle rail clamp',
        unit: MeasurementUnit.mm,
        value: 710,
      ),
    });

    final diff = compareSnapshots(s1, s2);
    expect(diff['saddle']!.status, ComparisonStatus.differentReference);
    expect(diff['saddle']!.delta, isNull);
    expect(diff['saddle']!.display, 'differentReference');
  });

  test('unit mismatch, unknown values, and missing fields flag clearly', () {
    final s1 = makeSnapshot('s1', t0, {
      'reach': MeasurementPoint(
        id: 'reach',
        label: 'Bar reach',
        referenceMethod: 'Saddle tip to bar center',
        unit: MeasurementUnit.mm,
        value: 520,
      ),
      'drop': MeasurementPoint(
        id: 'drop',
        label: 'Saddle-to-bar drop',
        referenceMethod: 'Laser level relative',
        unit: MeasurementUnit.mm,
      ),
      'setback': MeasurementPoint(
        id: 'setback',
        label: 'Saddle setback',
        referenceMethod: 'Plumb line behind BB',
        unit: MeasurementUnit.mm,
        value: 65,
      ),
    });

    final s2 = makeSnapshot('s2', t1, {
      'reach': MeasurementPoint(
        id: 'reach',
        label: 'Bar reach',
        referenceMethod: 'Saddle tip to bar center',
        unit: MeasurementUnit.inch,
        value: 20.5,
      ),
      'drop': MeasurementPoint(
        id: 'drop',
        label: 'Saddle-to-bar drop',
        referenceMethod: 'Laser level relative',
        unit: MeasurementUnit.mm,
        value: 40,
      ),
    });

    final diff = compareSnapshots(s1, s2);
    expect(diff['reach']!.status, ComparisonStatus.differentUnit);
    expect(diff['reach']!.delta, isNull);
    expect(diff['drop']!.status, ComparisonStatus.unknown);
    expect(diff['drop']!.delta, isNull);
    expect(diff['setback']!.status, ComparisonStatus.missing);
    expect(diff['setback']!.delta, isNull);
  });

  test('reversible history restores prior snapshot with explicit lineage', () {
    final s1 = makeSnapshot('s1', t0, {
      'saddle': MeasurementPoint(
        id: 'saddle',
        label: 'Saddle height',
        referenceMethod: 'BB to top center',
        unit: MeasurementUnit.mm,
        value: 740,
      ),
    });
    final s2 = makeSnapshot('s2', t1, {
      'saddle': MeasurementPoint(
        id: 'saddle',
        label: 'Saddle height',
        referenceMethod: 'BB to top center',
        unit: MeasurementUnit.mm,
        value: 750,
      ),
    });

    var history = SnapshotHistory([s1, s2]);
    final t2 = DateTime.parse('2026-11-03T09:00:00Z');
    history = history.restore(
      sourceId: 's1',
      newId: 's3',
      takenAt: t2,
      componentChanges: 'Reverted knee adjustment back to baseline',
    );

    expect(history.snapshots.length, 3);
    final restored = history.snapshots.last;
    expect(restored.id, 's3');
    expect(restored.sourceSnapshotId, 's1');
    expect(restored.measurements['saddle']!.value, 740);

    // Delta between baseline and reverted snapshot is 0 mm
    final deltaFromBaseline = compareSnapshots(s1, restored);
    expect(deltaFromBaseline['saddle']!.delta, 0.0);
  });
}

import 'domain.dart';

/// A complete, immutable set of measurements taken at one moment.
class SetupSnapshot {
  final String id;
  final DateTime takenAt;
  final String componentChanges;
  final String? sourceSnapshotId;
  final Map<String, MeasurementPoint> measurements;

  SetupSnapshot({
    required this.id,
    required this.takenAt,
    required Map<String, MeasurementPoint> measurements,
    this.componentChanges = '',
    this.sourceSnapshotId,
  }) : measurements = Map.unmodifiable(measurements) {
    if (id.trim().isEmpty || id != id.trim()) {
      throw const FormatException('Snapshot id must be non-empty and trimmed');
    }
    if (sourceSnapshotId != null &&
        (sourceSnapshotId!.trim().isEmpty || sourceSnapshotId == id)) {
      throw const FormatException('Invalid source snapshot id');
    }
    if (measurements.entries.any((entry) => entry.key != entry.value.id)) {
      throw const FormatException('Measurement key must equal point id');
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'takenAt': takenAt.toUtc().toIso8601String(),
    'componentChanges': componentChanges,
    'sourceSnapshotId': sourceSnapshotId,
    'measurements': [
      for (final key in measurements.keys.toList()..sort())
        measurements[key]!.toJson(),
    ],
  };

  factory SetupSnapshot.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Snapshot must be an object');
    }
    final id = json['id'];
    final date = json['takenAt'];
    final summary = json['componentChanges'];
    final source = json['sourceSnapshotId'];
    final raw = json['measurements'];
    if (id is! String ||
        date is! String ||
        summary is! String ||
        (source != null && source is! String) ||
        raw is! List) {
      throw const FormatException('Invalid snapshot fields');
    }
    final takenAt = DateTime.tryParse(date);
    if (takenAt == null || !date.endsWith('Z')) {
      throw const FormatException('Snapshot date must be UTC ISO-8601');
    }
    final points = raw.map(MeasurementPoint.fromJson).toList();
    final keyed = {for (final point in points) point.id: point};
    if (keyed.length != points.length) {
      throw const FormatException('Duplicate measurement id');
    }
    return SetupSnapshot(
      id: id,
      takenAt: takenAt,
      componentChanges: summary,
      sourceSnapshotId: source as String?,
      measurements: keyed,
    );
  }
}

enum ComparisonStatus {
  comparable,
  missing,
  unknown,
  differentReference,
  differentUnit,
}

class MeasurementComparison {
  final ComparisonStatus status;
  final double? delta;
  final MeasurementUnit? unit;

  const MeasurementComparison(this.status, {this.delta, this.unit});

  /// Only comparable results can be printed as signed differences.
  String get display {
    if (status != ComparisonStatus.comparable) return status.name;
    final number = delta == 0 ? 0.0 : delta!;
    final prefix = number >= 0 ? '+' : '';
    final fixed = number.toStringAsFixed(3);
    final trimmed = fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return '$prefix$trimmed ${unit == MeasurementUnit.inch ? 'in' : unit!.name}';
    // ponytail: display rounds to 0.001; keep raw delta for calculations.
  }
}

/// Direction: `before` to `after`. Never infer a delta across reference changes.
Map<String, MeasurementComparison> compareSnapshots(
  SetupSnapshot before,
  SetupSnapshot after,
) {
  final keys = {
    ...before.measurements.keys,
    ...after.measurements.keys,
  }.toList()..sort();
  return Map.unmodifiable({
    for (final id in keys)
      id: _compare(before.measurements[id], after.measurements[id]),
  });
}

MeasurementComparison _compare(
  MeasurementPoint? before,
  MeasurementPoint? after,
) {
  if (before == null || after == null) {
    return const MeasurementComparison(ComparisonStatus.missing);
  }
  if (before.referenceMethod != after.referenceMethod ||
      before.label != after.label) {
    return const MeasurementComparison(ComparisonStatus.differentReference);
  }
  if (before.unit != after.unit) {
    return const MeasurementComparison(ComparisonStatus.differentUnit);
  }
  if (before.value == null || after.value == null) {
    return const MeasurementComparison(ComparisonStatus.unknown);
  }
  return MeasurementComparison(
    ComparisonStatus.comparable,
    delta: after.value! - before.value!,
    unit: before.unit,
  );
}

/// Appending an old state creates a new entry; old snapshots remain untouched.
class SnapshotHistory {
  final List<SetupSnapshot> snapshots;

  SnapshotHistory(Iterable<SetupSnapshot> snapshots)
    : snapshots = List.unmodifiable(snapshots) {
    if (this.snapshots.map((s) => s.id).toSet().length !=
        this.snapshots.length) {
      throw const FormatException('Duplicate snapshot id');
    }
  }

  SnapshotHistory append(SetupSnapshot next) =>
      SnapshotHistory([...snapshots, next]);

  SnapshotHistory restore({
    required String sourceId,
    required String newId,
    required DateTime takenAt,
    String componentChanges = '',
  }) {
    final matches = snapshots.where((s) => s.id == sourceId);
    if (matches.isEmpty) throw const FormatException('Unknown source snapshot');
    if (snapshots.any((s) => s.id == newId)) {
      throw const FormatException('Duplicate snapshot id');
    }
    return append(
      SetupSnapshot(
        id: newId,
        takenAt: takenAt,
        sourceSnapshotId: sourceId,
        componentChanges: componentChanges,
        measurements: matches.single.measurements,
      ),
    );
  }
}

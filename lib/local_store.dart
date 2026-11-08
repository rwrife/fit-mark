import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'domain.dart';
import 'ride_notes.dart';
import 'snapshots.dart';

/// One validated document per commit: failed imports never touch live data.
class FitMarkData {
  final Map<String, Bike> bikes;
  final Map<String, SnapshotHistory> histories;
  final List<RideNote> notes;

  FitMarkData({
    Map<String, Bike> bikes = const {},
    Map<String, SnapshotHistory> histories = const {},
    Iterable<RideNote> notes = const [],
  }) : bikes = Map.unmodifiable(bikes),
       histories = Map.unmodifiable(histories),
       notes = List.unmodifiable(notes) {
    if (this.bikes.keys.any((id) => id.trim().isEmpty || id != id.trim()) ||
        this.histories.keys.any((id) => !this.bikes.containsKey(id)) ||
        this.bikes.keys.any((id) => !this.histories.containsKey(id))) {
      throw const FormatException('Invalid bike and history references');
    }
    for (final entry in this.histories.entries) {
      for (final snapshot in entry.value.snapshots) {
        if (snapshot.sourceSnapshotId != null &&
            !entry.value.snapshots.any(
              (s) => s.id == snapshot.sourceSnapshotId,
            )) {
          throw const FormatException('Unknown source snapshot');
        }
      }
    }
    RideJournal(histories: this.histories, notes: this.notes);
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'bikes': [
      for (final id in bikes.keys.toList()..sort())
        {'id': id, ...bikes[id]!.toJson()},
    ],
    'histories': {
      for (final id in histories.keys.toList()..sort())
        id: [
          for (final snapshot in histories[id]!.snapshots) snapshot.toJson(),
        ],
    },
    'notes': [for (final note in notes) note.toJson()],
  });

  factory FitMarkData.importJson(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const FormatException('Invalid JSON backup');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup must be an object');
    }
    // ponytail: no released v0 document exists; reject unknown schema rather
    // than guessing a migration. Add explicit migrators when v2 ships.
    if (decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported backup schema version');
    }
    final rawBikes = decoded['bikes'];
    final rawHistories = decoded['histories'];
    final rawNotes = decoded['notes'];
    if (rawBikes is! List ||
        rawHistories is! Map<String, dynamic> ||
        rawNotes is! List) {
      throw const FormatException('Invalid backup collections');
    }
    final bikes = <String, Bike>{};
    for (final raw in rawBikes) {
      if (raw is! Map<String, dynamic> || raw['id'] is! String) {
        throw const FormatException('Invalid bike record');
      }
      final id = raw['id'] as String;
      if (bikes.containsKey(id)) {
        throw const FormatException('Duplicate bike id');
      }
      bikes[id] = Bike.fromJson(raw);
    }
    final histories = <String, SnapshotHistory>{};
    for (final entry in rawHistories.entries) {
      if (entry.value is! List) {
        throw const FormatException('Invalid snapshot history');
      }
      histories[entry.key] = SnapshotHistory(
        (entry.value as List).map(SetupSnapshot.fromJson),
      );
    }
    return FitMarkData(
      bikes: bikes,
      histories: histories,
      notes: rawNotes.map(RideNote.fromJson),
    );
  }

  /// Current dimensions only; unknowns stay unknown, never zero.
  String setupSheet(String bikeId) {
    final bike = bikes[bikeId];
    final history = histories[bikeId];
    if (bike == null || history == null) {
      throw const FormatException('Unknown bike');
    }
    final lines = <String>[
      'Fit Mark · ${bike.name}',
      [bike.make, bike.model, bike.type].where((s) => s.isNotEmpty).join(' · '),
      'Measured by rider · not a fit or medical recommendation',
    ];
    if (history.snapshots.isEmpty) {
      lines.add('No setup snapshots recorded.');
    } else {
      final latest = history.snapshots.last;
      lines.add('Snapshot: ${latest.takenAt.toLocal().toIso8601String()}');
      if (latest.componentChanges.isNotEmpty) {
        lines.add(latest.componentChanges);
      }
      for (final point in latest.measurements.values) {
        lines.add(
          '${point.label}: ${point.value?.toString() ?? 'unknown'} ${point.unit.name} · ${point.referenceMethod}',
        );
      }
    }
    return '${lines.join('\n')}\n';
  }
}

class LocalStore {
  final Box<String> _box;
  static const _key = 'document';
  LocalStore(this._box);

  static Future<LocalStore> open() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}fitmark');
    await dir.create(recursive: true);
    // ponytail: Hive has one document key; add transactional multi-box schema
    // only if data exceeds a practical single-document size.
    return LocalStore(await Hive.openBox<String>('fitmark', path: dir.path));
  }

  FitMarkData load() {
    final text = _box.get(_key);
    return text == null ? FitMarkData() : FitMarkData.importJson(text);
  }

  Future<void> save(FitMarkData data) async {
    await _box.put(_key, data.exportJson());
    await _box.flush();
  }

  Future<void> close() => _box.close();
}

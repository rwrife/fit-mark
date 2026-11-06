import 'snapshots.dart';

/// Rider-authored impressions only; ratings have no clinical meaning.
class RideNote {
  final String id;
  final String bikeId;
  final String snapshotId;
  final DateTime riddenAt;
  final int? durationMinutes;
  final double? distanceKm;
  final int comfort; // 1 (uncomfortable) through 5 (comfortable).
  final String terrain;
  final String impressions;

  RideNote({
    required this.id,
    required this.bikeId,
    required this.snapshotId,
    required this.riddenAt,
    required this.comfort,
    required String terrain,
    required String impressions,
    this.durationMinutes,
    this.distanceKm,
  }) : terrain = terrain.trim(),
       impressions = impressions.trim() {
    if (id.trim().isEmpty ||
        id != id.trim() ||
        bikeId.trim().isEmpty ||
        bikeId != bikeId.trim() ||
        snapshotId.trim().isEmpty ||
        snapshotId != snapshotId.trim()) {
      throw const FormatException(
        'Ride and reference IDs must be non-empty and trimmed',
      );
    }
    if (comfort < 1 || comfort > 5) {
      throw const FormatException('Comfort rating must be 1 through 5');
    }
    if (durationMinutes != null && durationMinutes! < 0) {
      throw const FormatException('Duration cannot be negative');
    }
    if (distanceKm != null && (!distanceKm!.isFinite || distanceKm! < 0)) {
      throw const FormatException('Distance must be finite and non-negative');
    }
    if (this.impressions.isEmpty) {
      throw const FormatException('Ride impressions cannot be empty');
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'bikeId': bikeId,
    'snapshotId': snapshotId,
    'riddenAt': riddenAt.toUtc().toIso8601String(),
    'durationMinutes': durationMinutes,
    'distanceKm': distanceKm,
    'comfort': comfort,
    'terrain': terrain,
    'impressions': impressions,
  };

  factory RideNote.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Ride note must be an object');
    }
    final date = json['riddenAt'];
    final duration = json['durationMinutes'];
    final distance = json['distanceKm'];
    final comfort = json['comfort'];
    if (date is! String ||
        !date.endsWith('Z') ||
        DateTime.tryParse(date) == null ||
        (duration != null && duration is! int) ||
        (distance != null && distance is! num) ||
        comfort is! int ||
        json['terrain'] is! String ||
        json['impressions'] is! String) {
      throw const FormatException('Invalid ride note fields');
    }
    return RideNote(
      id: _requiredString(json['id'], 'id'),
      bikeId: _requiredString(json['bikeId'], 'bikeId'),
      snapshotId: _requiredString(json['snapshotId'], 'snapshotId'),
      riddenAt: DateTime.parse(date),
      durationMinutes: duration as int?,
      distanceKm: (distance as num?)?.toDouble(),
      comfort: comfort,
      terrain: json['terrain'] as String,
      impressions: json['impressions'] as String,
    );
  }
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$field must be non-empty and trimmed');
  }
  return value;
}

/// Snapshot ownership comes from bike-scoped histories, never a free-text name.
class RideJournal {
  final Map<String, SnapshotHistory> histories;
  final List<RideNote> notes;

  RideJournal({
    required Map<String, SnapshotHistory> histories,
    Iterable<RideNote> notes = const [],
  }) : histories = Map.unmodifiable(histories),
       notes = List.unmodifiable(notes) {
    for (final id in this.histories.keys) {
      _requiredString(id, 'bikeId');
    }
    if (this.notes.map((note) => note.id).toSet().length != this.notes.length) {
      throw const FormatException('Duplicate ride note id');
    }
    for (final note in this.notes) {
      final history = this.histories[note.bikeId];
      if (history == null ||
          !history.snapshots.any(
            (snapshot) => snapshot.id == note.snapshotId,
          )) {
        throw const FormatException(
          'Ride note references unknown bike or snapshot',
        );
      }
    }
  }

  RideJournal add(RideNote note) =>
      RideJournal(histories: histories, notes: [...notes, note]);

  List<RideNote> forBike(String bikeId, {String? snapshotId}) =>
      List.unmodifiable(
        notes
            .where(
              (note) =>
                  note.bikeId == bikeId &&
                  (snapshotId == null || note.snapshotId == snapshotId),
            )
            .toList()
          ..sort((a, b) => b.riddenAt.compareTo(a.riddenAt)),
      );

  // ponytail: in-memory associations until versioned offline store lands in #6.
}

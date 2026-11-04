/// Pure, offline bicycle measurement model. No clinical interpretation.
enum MeasurementUnit { mm, cm, inch, deg }

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be non-empty');
  }
  return value.trim();
}

String _optionalText(Object? value, String field) {
  if (value == null) return '';
  if (value is! String) throw FormatException('$field must be text');
  return value.trim();
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

/// Converts compatible linear units; angles are only comparable with angles.
/// Rejects non-finite and out-of-range values instead of silently rounding.
double convertMeasurement(
  double value,
  MeasurementUnit from,
  MeasurementUnit to,
) {
  if (!value.isFinite) {
    throw const FormatException('Measurement must be finite');
  }
  if ((from == MeasurementUnit.deg) != (to == MeasurementUnit.deg)) {
    throw const FormatException('Angle and length units are incompatible');
  }
  const factors = {
    MeasurementUnit.mm: 1.0,
    MeasurementUnit.cm: 10.0,
    MeasurementUnit.inch: 25.4,
    MeasurementUnit.deg: 1.0,
  };
  final base = value * factors[from]!;
  if (!base.isFinite || base.abs() > 1000000000) {
    throw const FormatException(
      'Measurement exceeds supported precision range',
    );
  }
  final result = base / factors[to]!;
  if (!result.isFinite) throw const FormatException('Measurement overflow');
  return result;
}

class MeasurementPoint {
  final String id;
  final String label;

  /// Exact physical start/end points and tool/method used by rider.
  final String referenceMethod;
  final MeasurementUnit unit;
  final double? value;

  MeasurementPoint({
    required String id,
    required String label,
    required String referenceMethod,
    required this.unit,
    this.value,
  }) : id = _text(id, 'id'),
       label = _text(label, 'label'),
       referenceMethod = _text(referenceMethod, 'referenceMethod') {
    if (value != null) convertMeasurement(value!, unit, unit);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'referenceMethod': referenceMethod,
    'unit': unit.name,
    'value': value,
  };

  factory MeasurementPoint.fromJson(Object? json) {
    final map = _object(json);
    final rawUnit = map['unit'];
    if (rawUnit is! String) throw const FormatException('Invalid unit');
    final unit = MeasurementUnit.values
        .where((u) => u.name == rawUnit)
        .firstOrNull;
    if (unit == null) throw const FormatException('Invalid unit');
    final rawValue = map['value'];
    if (rawValue != null && rawValue is! num) {
      throw const FormatException('Measurement value must be numeric or null');
    }
    return MeasurementPoint(
      id: _text(map['id'], 'id'),
      label: _text(map['label'], 'label'),
      referenceMethod: _text(map['referenceMethod'], 'referenceMethod'),
      unit: unit,
      value: (rawValue as num?)?.toDouble(),
    );
  }
}

class Bike {
  final String name;
  final String make;
  final String model;
  final String type;
  final String notes;
  final List<MeasurementPoint> points;

  Bike({
    required String name,
    required String make,
    required String model,
    required String type,
    String notes = '',
    List<MeasurementPoint> points = const [],
  }) : name = _text(name, 'name'),
       make = _optionalText(make, 'make'),
       model = _optionalText(model, 'model'),
       type = _text(type, 'type'),
       notes = _optionalText(notes, 'notes'),
       points = List.unmodifiable(points) {
    if (this.points.map((p) => p.id).toSet().length != this.points.length) {
      throw const FormatException('Duplicate measurement point id');
    }
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'make': make,
    'model': model,
    'type': type,
    'notes': notes,
    'points': points.map((point) => point.toJson()).toList(),
  };

  factory Bike.fromJson(Object? json) {
    final map = _object(json);
    final rawPoints = map['points'];
    if (rawPoints is! List) {
      throw const FormatException('points must be a list');
    }
    return Bike(
      name: _text(map['name'], 'name'),
      make: _optionalText(map['make'], 'make'),
      model: _optionalText(map['model'], 'model'),
      type: _text(map['type'], 'type'),
      notes: _optionalText(map['notes'], 'notes'),
      points: rawPoints.map(MeasurementPoint.fromJson).toList(),
    );
  }
}

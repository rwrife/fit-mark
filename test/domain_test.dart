import 'dart:convert';

import 'package:fitmark/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown stays unknown, zero stays zero across JSON', () {
    final bike = Bike(
      name: 'Road bike',
      make: '',
      model: '',
      type: 'road',
      points: [
        MeasurementPoint(
          id: 'saddle',
          label: 'Saddle height',
          referenceMethod: 'BB center to saddle top at center',
          unit: MeasurementUnit.mm,
        ),
        MeasurementPoint(
          id: 'angle',
          label: 'Saddle angle',
          referenceMethod: 'level across saddle',
          unit: MeasurementUnit.deg,
          value: 0,
        ),
      ],
    );
    final roundTrip = Bike.fromJson(jsonDecode(jsonEncode(bike.toJson())));
    expect(roundTrip.points[0].value, isNull);
    expect(roundTrip.points[1].value, 0);
    expect(roundTrip.points[0].referenceMethod, bike.points[0].referenceMethod);
    expect(
      () => roundTrip.points.add(bike.points.first),
      throwsUnsupportedError,
    );
  });

  test('conversion preserves precision, sign and compatible dimensions', () {
    expect(
      convertMeasurement(1, MeasurementUnit.inch, MeasurementUnit.mm),
      25.4,
    );
    expect(
      convertMeasurement(-2.54, MeasurementUnit.cm, MeasurementUnit.inch),
      closeTo(-1, 1e-12),
    );
    expect(convertMeasurement(0, MeasurementUnit.deg, MeasurementUnit.deg), 0);
    expect(
      () => convertMeasurement(1, MeasurementUnit.deg, MeasurementUnit.mm),
      throwsFormatException,
    );
    expect(
      () => convertMeasurement(
        double.nan,
        MeasurementUnit.mm,
        MeasurementUnit.mm,
      ),
      throwsFormatException,
    );
    expect(
      () => convertMeasurement(
        double.infinity,
        MeasurementUnit.mm,
        MeasurementUnit.cm,
      ),
      throwsFormatException,
    );
    expect(
      () => convertMeasurement(1e12, MeasurementUnit.mm, MeasurementUnit.mm),
      throwsFormatException,
    );
  });

  test('invalid and ambiguous records fail closed', () {
    expect(
      () => MeasurementPoint.fromJson({
        'id': 'x',
        'label': 'X',
        'referenceMethod': 'r',
        'unit': 'feet',
      }),
      throwsFormatException,
    );
    expect(
      () => MeasurementPoint.fromJson({
        'id': 'x',
        'label': 'X',
        'referenceMethod': 'r',
        'unit': 'mm',
        'value': '0',
      }),
      throwsFormatException,
    );
    expect(
      () => MeasurementPoint(
        id: 'x',
        label: 'X',
        referenceMethod: ' ',
        unit: MeasurementUnit.mm,
      ),
      throwsFormatException,
    );
    expect(
      () => Bike(
        name: 'A',
        make: '',
        model: '',
        type: 'road',
        points: [
          MeasurementPoint(
            id: 'x',
            label: 'X',
            referenceMethod: 'r',
            unit: MeasurementUnit.mm,
          ),
          MeasurementPoint(
            id: 'x',
            label: 'Y',
            referenceMethod: 'r',
            unit: MeasurementUnit.cm,
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => Bike.fromJson({'name': 'A', 'type': 'road', 'points': {}}),
      throwsFormatException,
    );
  });
}

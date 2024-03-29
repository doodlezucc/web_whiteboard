import 'dart:math';

import 'binary.dart';

final _decimal = RegExp(r'^\d*\.?\d+');

class Stroke implements Serializable {
  final List<Point<int>> points;
  String stroke;
  String strokeWidth;

  num get strokeWidthNum =>
      num.parse(_decimal.firstMatch(strokeWidth)!.group(0)!);

  Stroke({
    List<Point<int>>? points,
    this.stroke = '#000000',
    this.strokeWidth = '1px',
  }) : points = points ?? [];

  void add(Point<int> p) {
    // Limit amount of points to fit into a UInt16
    if (points.length >= 0xFFFF) return;
    points.add(p);
  }

  String toData() {
    if (points.isEmpty) return '';

    String writePoint(Point<int> p) {
      return ' ${p.x} ${p.y}';
    }

    var s = 'M' + writePoint(points.first);

    for (var p in points) {
      s += ' L' + writePoint(p);
    }

    return s;
  }

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.writeUInt16(points.length);
    for (var p in points) {
      writer.writePoint(p);
    }
    writer.writeString(stroke);
    writer.writeString(strokeWidth);
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    var count = reader.readUInt16();
    for (var i = 0; i < count; i++) {
      points.add(reader.readPoint());
    }
    stroke = reader.readString();
    strokeWidth = reader.readString();
  }
}

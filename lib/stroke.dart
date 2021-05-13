import 'dart:math';

import 'package:web_drawing/binary.dart';

class Stroke {
  List<Point> points;
  String stroke;
  String strokeWidth;

  Stroke({
    this.points,
    this.stroke,
    this.strokeWidth = '1px',
  }) {
    points ??= [];
  }

  void add(Point p) => points.add(p);

  String toData() {
    if (points.isEmpty) return '';

    String writePoint(Point p) {
      return ' ${p.x} ${p.y}';
    }

    var s = 'M' + writePoint(points.first);

    for (var p in points) {
      s += ' L' + writePoint(p);
    }

    return s;
  }

  void writeToBytes(BinaryWriter writer) {
    writer.writeUInt32(points.length);
    for (var p in points) {
      writer.writePoint(p);
    }
    writer.writeString(stroke);
    writer.writeString(strokeWidth);
  }

  void loadFromBytes(BinaryReader reader) {
    var count = reader.readUInt32();
    for (var i = 0; i < count; i++) {
      points.add(reader.readPoint());
    }
    stroke = reader.readString();
    strokeWidth = reader.readString();
  }
}

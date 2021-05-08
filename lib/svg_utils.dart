import 'dart:math';

import 'dart:svg' as svg;

import 'package:web_drawing/binary.dart';

class SvgPath {
  List<Point> points;
  String fill;
  String stroke;
  String strokeWidth;

  SvgPath({
    this.points,
    this.fill,
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

  void applyTo(svg.PathElement element) {
    element.setAttribute('d', toData());
    element.setAttribute('stroke', stroke);
    element.setAttribute('fill', fill);
    element.setAttribute('stroke-width', strokeWidth);
    element.setAttribute('stroke-linecap', 'round');
  }

  void writeToBytes(BinaryWriter writer) {
    writer.writeUInt32(points.length);
    for (var p in points) {
      writer.writePoint(p);
    }
    writer.writeString(stroke);
    writer.writeString(fill);
    writer.writeString(strokeWidth);
  }

  void loadFromBytes(BinaryReader reader) {
    var count = reader.readUInt32();
    for (var i = 0; i < count; i++) {
      points.add(reader.readPoint());
    }
    stroke = reader.readString();
    fill = reader.readString();
    strokeWidth = reader.readString();
  }
}

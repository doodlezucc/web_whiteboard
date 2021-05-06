import 'dart:math';

import 'dart:svg' as svg;

class SvgPath {
  List<Point> points = [];
  String fill;
  String stroke;

  SvgPath({this.points, this.fill, this.stroke});

  void add(Point p) => points.add(p);

  String toData() {
    if (points.isEmpty) return '';

    String writePoint(Point p) {
      return ' ${p.x} ${p.y}';
    }

    var s = 'M' + writePoint(points.first);

    for (var p in points.sublist(1)) {
      s += ' L' + writePoint(p);
    }

    return s;
  }

  void applyTo(svg.PathElement element) {
    element.setAttribute('d', toData());
    element.setAttribute('stroke', stroke);
    element.setAttribute('fill', fill);
  }
}

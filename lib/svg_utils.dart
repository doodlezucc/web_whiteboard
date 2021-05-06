import 'dart:math';

import 'dart:svg' as svg;

class SvgPath {
  List<Point> points = [];
  String fill;
  String stroke;
  String strokeWidth;
  String strokeCap;

  SvgPath({
    this.points,
    this.fill,
    this.stroke,
    this.strokeWidth = '1px',
    this.strokeCap = 'round',
  });

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
    element.setAttribute('stroke-linecap', strokeCap);
  }
}

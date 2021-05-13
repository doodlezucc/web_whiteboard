import 'dart:math';
import 'dart:svg' as svg;

import 'stroke.dart';

void applyStroke(Stroke stroke, svg.PathElement element) {
  element.setAttribute('d', stroke.toData());
  element.setAttribute('stroke', stroke.stroke);
  element.setAttribute('stroke-width', stroke.strokeWidth);
  element.setAttribute('fill', 'transparent');
  element.setAttribute('stroke-linecap', 'round');
}

Point<int> forceIntPoint(Point p) {
  return Point<int>(p.x, p.y);
}

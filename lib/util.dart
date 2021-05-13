import 'dart:svg' as svg;

import 'package:web_drawing/stroke.dart';

void applyStroke(Stroke stroke, svg.PathElement element) {
  element.setAttribute('d', stroke.toData());
  element.setAttribute('stroke', stroke.stroke);
  element.setAttribute('stroke-width', stroke.strokeWidth);
  element.setAttribute('fill', 'transparent');
  element.setAttribute('stroke-linecap', 'round');
}

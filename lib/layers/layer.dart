import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_drawing/web_drawing.dart';

abstract class Layer {
  final DrawingCanvas canvas;
  final svg.SvgSvgElement el;
  bool visible = true;

  Layer(this.canvas) : el = svg.SvgSvgElement() {
    el.width.baseVal.valueAsString = '100%';
    el.height.baseVal.valueAsString = '100%';
    canvas.container.append(el);
  }

  void onClick(MouseEvent ev);
  void onMouseDown(Point first, Stream<Point> moveStream);
}

import 'dart:html';
import 'dart:svg';

import 'package:web_drawing/web_drawing.dart';

abstract class Layer {
  final DrawingCanvas canvas;
  final SvgSvgElement el;
  bool visible = true;

  Layer(this.canvas) : el = SvgSvgElement() {
    el.width.baseVal.valueAsString = '100%';
    el.height.baseVal.valueAsString = '100%';
    canvas.parent.append(el);
  }

  void onClick(MouseEvent ev);
  void onMouseDown(MouseEvent first, Stream<MouseEvent> moveStream);
}

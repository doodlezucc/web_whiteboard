import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_drawing/layers/layer.dart';
import 'package:web_drawing/svg_utils.dart';
import 'package:web_drawing/web_drawing.dart';

class DrawingLayer extends Layer {
  DrawingLayer(DrawingCanvas canvas) : super(canvas);

  @override
  void onClick(MouseEvent ev) {}

  @override
  void onMouseDown(Point first, Stream<Point> stream) {
    _handleDrawStream(first, stream);
  }

  void _handleDrawStream(Point first, Stream<Point> stream) {
    var pathEl = svg.PathElement();
    el.append(pathEl);

    var path = SvgPath(
      points: [first],
      stroke: '#000000',
      fill: 'transparent',
      strokeWidth: '5px',
    );

    path.applyTo(pathEl);

    var lastDraw = first;
    const minDistanceSquared = 12;

    stream.listen((p) {
      if (p.squaredDistanceTo(lastDraw) > minDistanceSquared) {
        path.add(p);
        path.applyTo(pathEl);
        lastDraw = p;
      }
    });
  }
}

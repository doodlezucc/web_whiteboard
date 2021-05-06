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
  void onMouseDown(MouseEvent first, Stream<MouseEvent> stream) {
    print('down');
    var pathEl = svg.PathElement();
    el.append(pathEl);

    var path = SvgPath(
      points: [first.offset],
      stroke: '#000000',
      fill: 'transparent',
    );

    stream.listen((event) {
      print('move');
      path.add(event.offset);
      path.applyTo(pathEl);
    }, onDone: () => print('up'));
  }
}

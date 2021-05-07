import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_drawing/binary.dart';
import 'package:web_drawing/layers/layer.dart';
import 'package:web_drawing/svg_utils.dart';
import 'package:web_drawing/web_drawing.dart';

class DrawingLayer extends Layer {
  final _paths = <SvgPath>[];

  DrawingLayer(DrawingCanvas canvas) : super(canvas);

  @override
  void onMouseDown(Point first, Stream<Point> stream) {
    if (canvas.eraser) {
      _handleEraseStream(first, stream);
    } else {
      _handleDrawStream(first, stream);
    }
  }

  void _handleDrawStream(Point first, Stream<Point> stream) {
    var pathEl = svg.PathElement();
    layerEl.append(pathEl);

    var path = SvgPath(
      points: [first],
      stroke: '#000000',
      fill: 'transparent',
      strokeWidth: '5px',
    );

    _paths.add(path);

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

  void _handleEraseStream(Point first, Stream<Point> stream) {
    var paths = List.from(layerEl.children);

    void eraseAt(Point p) {
      var svgPoint = layerEl.createSvgPoint()
        ..x = p.x
        ..y = p.y;
      var changed = false;

      for (svg.PathElement path in paths) {
        if (path.isPointInStroke(svgPoint)) {
          path.remove();
          changed = true;
        }
      }

      if (changed) {
        paths = List.from(layerEl.children);
      }
    }

    eraseAt(first);

    stream.listen(eraseAt);
  }

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.addUInt8(0); // Layer type
    writer.addUInt16(_paths.length);
    for (var path in _paths) {
      path.writeToBytes(writer);
    }
  }
}

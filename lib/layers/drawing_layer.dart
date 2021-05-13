import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/drawing_data.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/stroke.dart';
import 'package:web_whiteboard/util.dart';
import 'package:web_whiteboard/whiteboard.dart';

class DrawingLayer extends Layer with DrawingData {
  final _pathData = <svg.PathElement, Stroke>{};

  DrawingLayer(Whiteboard canvas) : super(canvas, svg.GElement());

  @override
  void onMouseDown(Point first, Stream<Point> stream) {
    if (canvas.eraser) {
      _handleEraseStream(first, stream);
    } else {
      _handleDrawStream(first, stream);
    }
  }

  svg.PathElement _addPath(Stroke data) {
    var pathEl = svg.PathElement();
    applyStroke(data, pathEl);
    layerEl.append(pathEl);
    _pathData[pathEl] = data;
    return pathEl;
  }

  void _handleDrawStream(Point first, Stream<Point> stream) {
    var path = Stroke(
      points: [first],
      stroke: '#000000',
      strokeWidth: '5px',
    );

    strokes.add(path);
    var pathEl = _addPath(path);

    var lastDraw = first;
    const minDistanceSquared = 12;

    stream.listen((p) {
      if (p.squaredDistanceTo(lastDraw) > minDistanceSquared) {
        path.add(p);
        applyStroke(path, pathEl);
        lastDraw = p;
      }
    });
  }

  void _handleEraseStream(Point first, Stream<Point> stream) {
    var paths = List.from(layerEl.children);

    void eraseAt(Point p) {
      var svgPoint = canvas.root.createSvgPoint()
        ..x = p.x
        ..y = p.y;
      var changed = false;

      for (svg.PathElement path in paths) {
        if (path.isPointInStroke(svgPoint)) {
          path.remove();
          _pathData.remove(path);
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
    super.writeToBytes(writer);
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    super.loadFromBytes(reader);
    for (var stroke in strokes) {
      _addPath(stroke);
    }
  }
}

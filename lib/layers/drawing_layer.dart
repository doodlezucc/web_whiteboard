import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_drawing/binary.dart';
import 'package:web_drawing/layers/layer.dart';
import 'package:web_drawing/stroke.dart';
import 'package:web_drawing/util.dart';
import 'package:web_drawing/web_drawing.dart';

class DrawingLayer extends Layer {
  final _pathData = <svg.PathElement, Stroke>{};

  DrawingLayer(DrawingCanvas canvas) : super(canvas, svg.GElement());

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
  int get layerType => 0;

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.writeUInt8(layerType); // Layer type
    writer.writeUInt16(_pathData.length);
    for (var data in _pathData.values) {
      data.writeToBytes(writer);
    }
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    var pathCount = reader.readUInt16();
    for (var i = 0; i < pathCount; i++) {
      var data = Stroke()..loadFromBytes(reader);
      _addPath(data);
    }
  }
}

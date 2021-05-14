import 'dart:async';
import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/history.dart';
import 'package:web_whiteboard/layers/drawing_data.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/stroke.dart';
import 'package:web_whiteboard/util.dart';
import 'package:web_whiteboard/whiteboard.dart';

class DrawingLayer extends Layer with DrawingData {
  final _pathData = <svg.PathElement, Stroke>{};

  DrawingLayer(Whiteboard canvas) : super(canvas, svg.GElement());

  @override
  Future<Action> onMouseDown(Point first, Stream<Point> stream) {
    if (canvas.eraser) {
      return _handleEraseStream(first, stream);
    } else {
      return _handleDrawStream(first, stream);
    }
  }

  svg.PathElement _addPath(Stroke data) {
    var pathEl = svg.PathElement();
    applyStroke(data, pathEl);
    layerEl.append(pathEl);
    _pathData[pathEl] = data;
    return pathEl;
  }

  Future<Action> _handleDrawStream(Point first, Stream<Point> stream) async {
    var completer = Completer();

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
    }, onDone: completer.complete);

    await completer.future;

    return StrokeAction(this, true, [path]);
  }

  void _erase(svg.PathElement pathEl) {
    pathEl.remove();
    strokes.remove(_pathData.remove(pathEl));
  }

  Future<Action> _handleEraseStream(Point first, Stream<Point> stream) async {
    var paths = List.from(layerEl.children);
    var erased = <Stroke>[];

    void eraseAt(Point p) {
      var svgPoint = canvas.root.createSvgPoint()
        ..x = p.x
        ..y = p.y;
      var changed = false;

      for (svg.PathElement path in paths) {
        if (path.isPointInStroke(svgPoint)) {
          erased.add(_pathData[path]);
          _erase(path);
          changed = true;
        }
      }

      if (changed) {
        paths = List.from(layerEl.children);
      }
    }

    eraseAt(first);
    stream.listen(eraseAt);

    return StrokeAction(this, false, erased);
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

class StrokeAction extends AddRemoveAction<Stroke> {
  final DrawingLayer layer;

  StrokeAction(this.layer, bool forward, Iterable<Stroke> list)
      : super(forward, list);

  @override
  void doSingle(Stroke stroke) {
    layer._addPath(stroke);
    layer.strokes.add(stroke);
  }

  @override
  void undoSingle(Stroke stroke) {
    layer._erase(
        layer._pathData.entries.firstWhere((n) => n.value == stroke).key);
  }

  @override
  void onExecuted(bool forward) {}
}

import 'dart:async';
import 'dart:html';
import 'dart:svg' as svg;

import '../binary.dart';
import '../communication/binary_event.dart';
import '../communication/event_type.dart';
import '../history.dart';
import '../stroke.dart';
import '../util.dart';
import '../whiteboard.dart';
import 'drawing_data.dart';
import 'drawn_stroke.dart';
import 'layer.dart';

class DrawingLayer extends Layer with DrawingData {
  final _pathData = <svg.PathElement, Stroke>{};
  int get indexInWhiteboard => canvas.layers.indexOf(this);

  DrawingLayer(Whiteboard canvas) : super(canvas, svg.GElement());

  @override
  Future<Action?> onMouseDown(Point first, Stream<Point> stream) {
    if (canvas.eraser) {
      return handleEraseStream(first, stream);
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

  Future<Action?> _handleDrawStream(Point first, Stream<Point> stream) async {
    // Prevent drawing new lines if limit of 255 strokes is reached
    if (strokes.length >= 0xFF) return null;

    var copy = List<Stroke>.from(strokes);
    var completer = Completer();

    var path = Stroke(
      points: [Point(first.x.toInt(), first.y.toInt())],
      stroke: canvas.activeColor,
      strokeWidth: '5px',
    );

    strokes.add(path);
    var pathEl = _addPath(path);

    var lastDraw = first;
    const minDistanceSquared = 8;

    stream.listen((p) {
      if (p.squaredDistanceTo(lastDraw) > minDistanceSquared) {
        path.add(Point(p.x.toInt(), p.y.toInt()));
        applyStroke(path, pathEl);
        lastDraw = p;
      }
    }, onDone: completer.complete);

    await completer.future;

    return StrokeAction(this, true, [path], copy);
  }

  void _erase(svg.PathElement pathEl) {
    pathEl.remove();
    strokes.remove(_pathData.remove(pathEl));
  }

  Iterable<Stroke> _eraseAt(Point p) {
    var paths = List.from(layerEl.children);
    var erased = <Stroke>[];
    var svgPoint = canvas.root.createSvgPoint()
      ..x = p.x
      ..y = p.y;

    for (svg.PathElement path in paths) {
      if (path.isPointInStroke(svgPoint)) {
        erased.add(_pathData[path]!);
        _erase(path);
      }
    }

    return erased;
  }

  Future<StrokeAction?> handleEraseStream(
      Point first, Stream<Point> stream) async {
    var copy = List<Stroke>.from(strokes);
    var erased = <Stroke>[];

    void eraseAtHelper(Point p) {
      erased.addAll(_eraseAt(p));
    }

    var completer = Completer();

    eraseAtHelper(first);
    stream.listen(eraseAtHelper, onDone: completer.complete);
    await completer.future;

    return erased.isEmpty ? null : StrokeAction(this, false, erased, copy);
  }

  void onClear() {
    for (var path in layerEl.children) {
      path.remove();
    }
    strokes.clear();
    _pathData.clear();
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
  final List<Stroke> strokesBefore;
  final DrawingLayer layer;

  StrokeAction(
      this.layer, bool forward, Iterable<Stroke> list, this.strokesBefore)
      : super(forward, list);

  void _sendDrawEvent() {
    if (userCreated) {
      final event = BinaryEvent(EventType.strokeCreate, drawingLayer: layer)
        ..writeUInt8(list.length);

      list.forEach((s) => s.writeToBytes(event));
      layer.canvas.socket.send(event);
    }
  }

  void _sendEraseEvent() {
    if (userCreated) {
      // Write erased stroke indices
      var event = BinaryEvent(1, drawingLayer: layer)..writeUInt8(list.length);
      list.forEach((s) {
        var bufferedIndex = strokesBefore.indexOf(s);
        var realIndex = layer.strokes.indexOf(s);
        event.writeUInt8(realIndex == -1 ? bufferedIndex : realIndex);
      });
      layer.canvas.socket.send(event);
    }
  }

  @override
  void doSingle(Stroke stroke) {
    layer._addPath(stroke);
    layer.strokes.add(stroke);
  }

  @override
  void onSilentRegister() {
    if (forward) {
      _sendDrawEvent();
    } else if (!forward) {
      _sendEraseEvent();
    }
  }

  @override
  void undoSingle(Stroke stroke) {
    layer._erase(
        layer._pathData.entries.firstWhere((n) => n.value == stroke).key);
  }

  @override
  void onBeforeExecute(bool forward) {
    forward ? _sendDrawEvent() : _sendEraseEvent();
  }
}

class StrokeAcrossAction extends AddRemoveAction<DrawnStroke> {
  final Map<DrawingLayer, List<Stroke>> strokesBefore;

  StrokeAcrossAction(
      bool forward, Iterable<DrawnStroke> list, this.strokesBefore)
      : super(forward, list);

  void _sendDrawEvent() {
    if (userCreated) {
      final event = BinaryEvent(EventType.strokeMultipleCreate)
        ..writeUInt8(list.length);

      list.forEach((s) {
        event.writeUInt8(s.layer.indexInWhiteboard);
        s.stroke.writeToBytes(event);
      });
      list.first.layer.canvas.socket.send(event);
    }
  }

  void _sendEraseEvent() {
    if (userCreated) {
      final event = BinaryEvent(EventType.strokeMultipleRemove)
        ..writeUInt8(list.length);

      list.forEach((s) {
        var bufferedIndex = strokesBefore[s.layer]!.indexOf(s.stroke);
        var realIndex = s.layer.strokes.indexOf(s.stroke);
        event.writeUInt8(s.layer.indexInWhiteboard);
        event.writeUInt8(realIndex == -1 ? bufferedIndex : realIndex);
      });
      list.first.layer.canvas.socket.send(event);
    }
  }

  @override
  void doSingle(DrawnStroke stroke) {
    stroke.layer._addPath(stroke.stroke);
    stroke.layer.strokes.add(stroke.stroke);
  }

  @override
  void onSilentRegister() {
    if (forward) {
      _sendDrawEvent();
    } else if (!forward) {
      _sendEraseEvent();
    }
  }

  @override
  void undoSingle(DrawnStroke stroke) {
    stroke.layer._erase(stroke.layer._pathData.entries
        .firstWhere((n) => n.value == stroke.stroke)
        .key);
  }

  @override
  void onBeforeExecute(bool forward) {
    forward ? _sendDrawEvent() : _sendEraseEvent();
  }
}

import 'dart:async';
import 'dart:html';

import 'package:web_drawing/layers/drawing_layer.dart';
import 'package:web_drawing/layers/layer.dart';

class DrawingCanvas {
  final HtmlElement container;
  final _layers = <Layer>[];
  int layerIndex = 0;
  bool eraser = false;

  Layer get layer => _layers[layerIndex];

  DrawingCanvas(this.container) {
    _initControls();
    _addLayer(DrawingLayer(this));
  }

  void _addLayer(Layer layer) {
    _layers.add(layer);
  }

  void _initControls() {
    StreamController<Point> moveStreamCtrl;

    void listenToCursorEvents<T extends Event>(
      Point Function(T ev) evToPoint,
      Stream<T> startEvent,
      Stream<T> moveEvent,
      Stream<T> endEvent,
    ) {
      startEvent.listen((ev) async {
        ev.preventDefault();
        moveStreamCtrl = StreamController();
        layer.onMouseDown(evToPoint(ev), moveStreamCtrl.stream);

        await endEvent.first;
        await moveStreamCtrl.close();
        moveStreamCtrl = null;
      });

      moveEvent.listen((ev) {
        if (moveStreamCtrl != null) {
          moveStreamCtrl.add(evToPoint(ev));
        }
      });
    }

    listenToCursorEvents<MouseEvent>((ev) => ev.page - container.documentOffset,
        container.onMouseDown, window.onMouseMove, window.onMouseUp);

    listenToCursorEvents<TouchEvent>(
        (ev) => ev.targetTouches[0].page - container.documentOffset,
        container.onTouchStart,
        window.onTouchMove,
        window.onTouchEnd);
  }
}

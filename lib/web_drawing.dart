import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:web_drawing/layers/drawing_layer.dart';
import 'package:web_drawing/layers/layer.dart';

class DrawingCanvas {
  final HtmlElement container;
  final _layers = <Layer>[];
  int layerIndex = 0;
  bool eraser = false;
  bool useShortcuts = true;

  Layer get layer => _layers[layerIndex];

  DrawingCanvas(this.container) {
    _initDom();
    _initCursorControls();
    _initShortcuts();
    _addLayer(DrawingLayer(this));
  }

  DrawingLayer addDrawingLayer() {
    return _addLayer(DrawingLayer(this));
  }

  L _addLayer<L extends Layer>(L layer) {
    _layers.add(layer);
    layerIndex = _layers.length - 1;
    return layer;
  }

  void _initDom() {
    if (container.style.position.isEmpty) {
      container.style.position = 'relative';
    }
  }

  void _initShortcuts() {
    window.onKeyDown.listen((ev) {
      if (useShortcuts && ev.target is! InputElement) {
        switch (ev.key) {
          case 'e':
            eraser = !eraser;
            return print('Eraser: $eraser');

          case 'D':
            addDrawingLayer();
            return print('Added drawing layer');

          case 'ArrowUp':
            layerIndex = min(_layers.length - 1, layerIndex + 1);
            return print('Layer: $layerIndex');

          case 'ArrowDown':
            layerIndex = max(0, layerIndex - 1);
            return print('Layer: $layerIndex');
        }
      }
    });
  }

  void _initCursorControls() {
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

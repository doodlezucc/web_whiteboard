import 'dart:async';
import 'dart:html';

import 'package:web_drawing/layers/drawing_layer.dart';
import 'package:web_drawing/layers/layer.dart';

class DrawingCanvas {
  final HtmlElement container;
  final _layers = <Layer>[];
  int layerIndex = 0;

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

    Point touchToPoint(TouchEvent ev) {
      return ev.targetTouches[0].page - container.documentOffset;
    }

    container
      ..onMouseDown.listen((ev) async {
        moveStreamCtrl = StreamController();
        layer.onMouseDown(ev.offset, moveStreamCtrl.stream);

        await window.onMouseUp.first;
        await moveStreamCtrl.close();
        moveStreamCtrl = null;
      })
      ..onTouchStart.listen((ev) async {
        ev.preventDefault();
        moveStreamCtrl = StreamController();
        layer.onMouseDown(touchToPoint(ev), moveStreamCtrl.stream);

        await window.onTouchEnd.first;
        await moveStreamCtrl.close();
        moveStreamCtrl = null;
      });

    window
      ..onMouseMove.listen((ev) {
        if (moveStreamCtrl != null) {
          moveStreamCtrl.add(ev.page - container.documentOffset);
        }
      })
      ..onTouchMove.listen((ev) {
        ev.preventDefault();
        if (moveStreamCtrl != null) {
          moveStreamCtrl.add(touchToPoint(ev));
        }
      });
  }
}

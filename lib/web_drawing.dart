import 'dart:async';
import 'dart:html';

import 'package:web_drawing/layers/drawing_layer.dart';
import 'package:web_drawing/layers/layer.dart';

class DrawingCanvas {
  final HtmlElement parent;
  final _layers = <Layer>[];
  int layerIndex = 0;

  Layer get layer => _layers[layerIndex];

  DrawingCanvas(this.parent) {
    _initControls();
    _addLayer(DrawingLayer(this));
  }

  void _addLayer(Layer layer) {
    _layers.add(layer);
  }

  void _initControls() {
    StreamController<MouseEvent> moveStreamController;
    var mouseButton = -1;

    parent
      ..onMouseDown.listen((ev) async {
        mouseButton = ev.button;
        moveStreamController = StreamController();
        layer.onMouseDown(ev, moveStreamController.stream);

        await window.onMouseUp.first;

        mouseButton = -1;
        await moveStreamController.close();
      })
      ..onMouseMove.listen((ev) {
        if (mouseButton == 0) {
          moveStreamController.add(ev);
        }
      });
  }
}

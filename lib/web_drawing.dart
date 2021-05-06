import 'dart:html';

import 'package:web_drawing/layer.dart';

class DrawingCanvas {
  final CanvasElement canvas;
  final _layers = <Layer>[];
  int layerIndex;

  Layer get layer => _layers[layerIndex];

  DrawingCanvas(this.canvas) {
    _initControls();
  }

  void _initControls() {
    var mouseDown = false;
    canvas
      ..onMouseDown.listen((ev) async {
        mouseDown = true;
        await window.onMouseUp.first;
        mouseDown = false;
      })
      ..onMouseMove.listen((ev) {});
  }
}

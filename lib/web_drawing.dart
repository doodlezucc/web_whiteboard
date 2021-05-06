import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:web_drawing/layers/drawing_layer.dart';
import 'package:web_drawing/layers/layer.dart';
import 'package:web_drawing/layers/text_layer.dart';

class DrawingCanvas {
  final HtmlElement container;
  final TextAreaElement textInput;
  final _layers = <Layer>[];

  int _layerIndex = 0;
  int get layerIndex => _layerIndex;
  set layerIndex(int layerIndex) {
    _layerIndex = layerIndex;

    if (layer is TextLayer) {
      textInput.text = (layer as TextLayer).text;
    }
  }

  bool eraser = false;
  bool useShortcuts = true;

  Layer get layer => _layers[layerIndex];

  DrawingCanvas(this.container, [TextAreaElement text])
      : textInput = text ?? TextAreaElement() {
    _initDom();
    _initTextInput();
    _initCursorControls();
    _initKeyListener();
    addTextLayer();
  }

  DrawingLayer addDrawingLayer() {
    return _addLayer(DrawingLayer(this));
  }

  TextLayer addTextLayer() {
    return _addLayer(TextLayer(this));
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

  void _initTextInput() {
    if (!textInput.isConnected) {
      container.append(textInput
        ..style.position = 'absolute'
        ..style.zIndex = '10'
        ..placeholder = 'Text...');
    }

    textInput.onInput.listen((ev) {
      if (layer is TextLayer) {
        (layer as TextLayer).text = textInput.value;
      }
    });
  }

  static bool isInput(Element e) => e is InputElement || e is TextAreaElement;

  void _initKeyListener() {
    window.onKeyDown.listen((ev) {
      if (useShortcuts && !isInput(ev.target)) {
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

        if (layer is TextLayer && ev.keyCode == 13) {
          textInput.focus();
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
        if (isInput(ev.target)) return;

        ev.preventDefault();
        document.activeElement.blur();
        moveStreamCtrl = StreamController.broadcast();
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

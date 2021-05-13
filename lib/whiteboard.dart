import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'dart:svg' as svg;
import 'dart:typed_data';

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/drawing_layer.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/layers/text_layer.dart';
import 'package:web_whiteboard/util.dart';

class Whiteboard {
  final HtmlElement _container;
  final svg.SvgSvgElement root;
  final TextAreaElement textInput;
  final _layers = <Layer>[];

  int _layerIndex = 0;
  int get layerIndex => _layerIndex;
  set layerIndex(int layerIndex) {
    _layerIndex = layerIndex;

    if (layer is TextLayer) {
      textInput.value = (layer as TextLayer).text;
      textInput.disabled = false;
    } else {
      textInput.value = '';
      textInput.disabled = true;
    }
  }

  static const modeDraw = 'draw';
  static const modeText = 'text';

  String _mode;
  String get mode => _mode;
  set mode(String mode) {
    _mode = mode;
    _container.setAttribute('mode', mode);
  }

  bool eraser = false;
  bool useShortcuts = true;

  Layer get layer => _layers[layerIndex];

  Whiteboard(HtmlElement container, [TextAreaElement text])
      : _container = container,
        textInput = text ?? TextAreaElement(),
        root = svg.SvgSvgElement() {
    _initDom();
    _initTextInput();
    _initCursorControls();
    _initKeyListener();
    addDrawingLayer();
    mode = modeText;

    root
      ..width.baseVal.valueAsString = '100%'
      ..height.baseVal.valueAsString = '100%';
    _container.append(root);
  }

  Uint8List saveToBytes() {
    var writer = BinaryWriter();
    writer.writeUInt16(_layers.length);
    for (var layer in _layers) {
      layer.writeToBytes(writer);
    }
    return writer.takeBytes();
  }

  void loadFromBytes(Uint8List bytes) {
    clear();
    var reader = BinaryReader(bytes.buffer);
    var layerCount = reader.readUInt16();
    for (var i = 0; i < layerCount; i++) {
      _addLayerType(reader.readUInt8()).loadFromBytes(reader);
    }
  }

  Layer _addLayerType(int type) {
    switch (type) {
      case 0:
        return addDrawingLayer();
      case 1:
        return addText();
    }
    return null;
  }

  String encode() => base64.encode(saveToBytes());
  void decode(String data) => loadFromBytes(base64.decode(data));

  void removeLayer(int index) {
    _layers[index].dispose();
    _layers.removeAt(index);
    if (_layerIndex == index) {
      layerIndex = index; // Yeah, this setter does something besides setting.
    } else if (_layerIndex > index || index == _layers.length) {
      layerIndex--;
    }
  }

  DrawingLayer addDrawingLayer() => _addLayer(DrawingLayer(this));

  TextLayer addText() => _addLayer(TextLayer(this));

  L _addLayer<L extends Layer>(L layer) {
    _layers.add(layer);
    layerIndex = _layers.length - 1;
    return layer;
  }

  void clear() {
    for (var l in _layers) {
      l.dispose();
    }
    _layers.clear();
  }

  void _initDom() {
    if (_container.style.position.isEmpty) {
      _container.style.position = 'relative';
    }
  }

  void _initTextInput() {
    if (!textInput.isConnected) {
      _container.append(textInput
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

  static bool _isInput(Element e) => e is InputElement || e is TextAreaElement;

  void _initKeyListener() {
    window.onKeyDown.listen((ev) {
      if (useShortcuts && !_isInput(ev.target)) {
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
    StreamController<Point<int>> moveStreamCtrl;

    void listenToCursorEvents<T extends Event>(
      Point Function(T ev) evToPoint,
      Stream<T> startEvent,
      Stream<T> moveEvent,
      Stream<T> endEvent,
    ) {
      startEvent.listen((ev) async {
        if (_isInput(ev.target)) return;

        ev.preventDefault();
        document.activeElement.blur();
        moveStreamCtrl = StreamController.broadcast();
        layer.onMouseDown(forceIntPoint(evToPoint(ev)), moveStreamCtrl.stream);

        await endEvent.first;
        await moveStreamCtrl.close();
        moveStreamCtrl = null;
      });

      moveEvent.listen((ev) {
        if (moveStreamCtrl != null) {
          moveStreamCtrl.add(forceIntPoint(evToPoint(ev)));
        }
      });
    }

    listenToCursorEvents<MouseEvent>(
        (ev) => ev.page - _container.documentOffset,
        _container.onMouseDown,
        window.onMouseMove,
        window.onMouseUp);

    listenToCursorEvents<TouchEvent>(
        (ev) => ev.targetTouches[0].page - _container.documentOffset,
        _container.onTouchStart,
        window.onTouchMove,
        window.onTouchEnd);
  }
}

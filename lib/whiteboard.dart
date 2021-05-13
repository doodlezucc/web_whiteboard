import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'dart:svg' as svg;

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/drawing_layer.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/layers/text_layer.dart';
import 'package:web_whiteboard/util.dart';
import 'package:web_whiteboard/whiteboard_data.dart';

class Whiteboard with WhiteboardData {
  static const modeDraw = 'draw';
  static const modeText = 'text';

  final HtmlElement _container;
  final svg.SvgSvgElement root;
  final TextAreaElement textInput;

  bool eraser = false;
  bool useShortcuts = true;

  DrawingLayer get layer => layers[layerIndex];

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

  String _mode;
  String get mode => _mode;
  set mode(String mode) {
    _mode = mode;
    _container.setAttribute('mode', mode);
  }

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

  @override
  void loadFromBytes(BinaryReader reader) {
    var layerCount = reader.readUInt16();
    for (var i = 0; i < layerCount; i++) {
      layers.add(DrawingLayer(this)..loadFromBytes(reader));
    }

    var textCount = reader.readUInt16();
    for (var i = 0; i < textCount; i++) {
      texts.add(TextLayer(this)..loadFromBytes(reader));
    }
  }

  String encode() {
    var writer = BinaryWriter();
    writeToBytes(writer);
    return base64.encode(writer.takeBytes());
  }

  void decode(String data) {
    var reader = BinaryReader(base64.decode(data).buffer);
    loadFromBytes(reader);
  }

  DrawingLayer addDrawingLayer() {
    var layer = DrawingLayer(this);
    layers.add(layer);
    return layer;
  }

  TextLayer addText() {
    var layer = TextLayer(this);
    texts.add(layer);
    return layer;
  }

  void clear() {
    for (var l in layers) {
      (l as Layer).dispose();
    }
    layers.clear();

    for (var t in texts) {
      (t as Layer).dispose();
    }
    texts.clear();
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
      print('BRUH');
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

        if (mode == modeText) ev.preventDefault();
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

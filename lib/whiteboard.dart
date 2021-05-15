import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'dart:svg' as svg;

import 'package:pedantic/pedantic.dart';
import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/history.dart';
import 'package:web_whiteboard/layers/drawing_layer.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/layers/text_layer.dart';
import 'package:web_whiteboard/util.dart';
import 'package:web_whiteboard/whiteboard_data.dart';

class Whiteboard with WhiteboardData {
  static const modeDraw = 'draw';
  static const modeText = 'text';

  final HtmlElement _container;
  final root = svg.SvgSvgElement();
  final _textControls = DivElement();
  final _textInput = TextAreaElement();
  final _fontSizeInput = InputElement(type: 'number');
  final textRemoveButton = ButtonElement();
  final history = History();

  bool eraser = false;
  bool useShortcuts = true;
  int layerIndex = 0;
  int defaultFontSize = 20;

  DrawingLayer get layer => layers[layerIndex];

  TextLayer selectedText;

  String _mode;
  String get mode => _mode;
  set mode(String mode) {
    _mode = mode;
    _container.setAttribute('mode', mode);
    _onTextDeselect();
  }

  Whiteboard(HtmlElement container, [TextAreaElement text])
      : _container = container {
    _initDom();
    _initTextControls();
    _initCursorControls();
    _initKeyListener();
    addDrawingLayer();
    mode = modeText;
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    var layerCount = reader.readUInt8();
    for (var i = 0; i < layerCount; i++) {
      layers.add(DrawingLayer(this)..loadFromBytes(reader));
    }

    var textCount = reader.readUInt8();
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
    // Limit amount of layers
    if (layers.length >= 0xFF) return layers[0];

    var layer = DrawingLayer(this);
    layers.add(layer);
    return layer;
  }

  TextLayer addText() {
    // Limit amount of texts
    if (texts.length >= 0xFF) return texts[0];

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

    _textControls
      ..id = 'whiteboardTextControls'
      ..append(_textInput..placeholder = 'Text...')
      ..append(SpanElement()
        ..text = 'Font size:'
        ..append(_fontSizeInput)
        ..append(textRemoveButton
          ..text = 'Remove'
          ..onClick.listen((_) => removeSelectedText())));

    root
      ..width.baseVal.valueAsString = '100%'
      ..height.baseVal.valueAsString = '100%';
    _container..append(root)..append(_textControls);
  }

  void _initTextControls() {
    _textInput.onInput.listen((ev) {
      selectedText?.text = _textInput.value;
    });
    _fontSizeInput.onInput.listen((ev) {
      selectedText?.fontSize = _fontSizeInput.valueAsNumber ?? 20;
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

          case 'Delete':
          case 'Backspace':
            return removeSelectedText();
        }

        if (ev.ctrlKey) {
          switch (ev.key) {
            case 'z':
              return history.undo();

            case 'y':
            case 'Z':
              return history.redo();
          }
        }
      }
    });
  }

  void removeSelectedText() {
    if (selectedText != null) {
      var register = !selectedText.isCreation;
      history.perform(
        TextInstanceAction(selectedText, selectedText.position, false),
        register,
      );
      _onTextDeselect();
    }
  }

  void _onTextSelect(Point<int> where, TextLayer text) {
    selectedText = text..focused = true;
    _textInput
      ..value = text.text
      ..disabled = false;
    _fontSizeInput
      ..valueAsNumber = text.fontSize
      ..disabled = false;

    var p = text.position;

    _textControls
      ..style.left = '${p.x}px'
      ..style.top = '${p.y}px'
      ..classes.toggle('hidden', false);

    Future.delayed(Duration(milliseconds: 1), () => _textInput.focus());
  }

  void _onTextDeselect() {
    _textControls.classes.toggle('hidden', true);
    _textInput.disabled = true;
    _fontSizeInput.disabled = true;
    selectedText?.focused = false;
    selectedText = null;
  }

  void _initCursorControls() {
    StreamController<Point<int>> moveStreamCtrl;

    void listenToCursorEvents<T extends Event>(
      Point Function(T ev) evToPoint,
      Stream<T> startEvent,
      Stream<T> moveEvent,
      Stream<T> endEvent,
    ) {
      Point<int> fixedPoint(T ev) => forceIntPoint(evToPoint(ev));

      startEvent.listen((ev) async {
        if (_isInput(ev.target) || !ev.path.any((e) => e == root)) return;

        Layer layer = this.layer;

        if (mode == modeText) {
          var textTarget = ev.path
              .firstWhere((e) => e is svg.TextElement, orElse: () => null);

          if (selectedText != null && textTarget == null) {
            if (!ev.path.any((e) => e == _textControls)) {
              _onTextDeselect();
            }
            return;
          }

          if (textTarget != null) {
            // User clicked on text object (probably)
            for (TextLayer textObj in texts) {
              if (textObj.textElement == textTarget) {
                layer = textObj;
                break;
              }
            }
          } else {
            // Create new text object
            layer = addText()
              ..position = fixedPoint(ev)
              ..fontSize = defaultFontSize
              ..text = 'Text';
          }
          _onTextDeselect();
          selectedText = layer;
        }

        ev.preventDefault();
        document.activeElement.blur();
        moveStreamCtrl = StreamController.broadcast();

        var action = Completer();
        unawaited(
            layer.onMouseDown(fixedPoint(ev), moveStreamCtrl.stream).then((a) {
          action.complete(a);
        }));

        await endEvent.first;
        await moveStreamCtrl.close();
        moveStreamCtrl = null;

        if (mode == modeText && layer.layerEl.isConnected) {
          _onTextSelect(fixedPoint(ev), layer);
        }

        history.registerDoneAction(await action.future);
      });

      moveEvent.listen((ev) {
        if (moveStreamCtrl != null) {
          moveStreamCtrl.add(fixedPoint(ev));
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

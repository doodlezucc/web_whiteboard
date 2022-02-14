import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'dart:svg' as svg;

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/communication/binary_event.dart';
import 'package:web_whiteboard/history.dart';
import 'package:web_whiteboard/layers/drawing_layer.dart';
import 'package:web_whiteboard/layers/drawn_stroke.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/layers/pin_layer.dart';
import 'package:web_whiteboard/layers/text_layer.dart';
import 'package:web_whiteboard/stroke.dart';
import 'package:web_whiteboard/util.dart';
import 'package:web_whiteboard/communication/web_socket.dart';
import 'package:web_whiteboard/whiteboard_data.dart';

class Whiteboard with WhiteboardData {
  static const modeDraw = 'draw';
  static const modeText = 'text';
  static const modePin = 'pin';

  final HtmlElement _container;
  final root = svg.SvgSvgElement();
  final _img = ImageElement();
  final _background = svg.ImageElement();
  final _textControls = DivElement();
  final _textInput = TextAreaElement();
  final _fontSizeInput = InputElement(type: 'number');
  final textRemoveButton = ButtonElement();
  final history = History();
  final socket = WhiteboardSocket();

  bool eraser = false;
  bool eraseAcrossLayers = false;
  bool captureInput = true;
  int layerIndex = 0;
  int defaultFontSize = 20;
  double _zoomCorrection = 1;
  String activeColor = '#000000';
  double textControlsWrapMin;
  bool Function(Event event) useStartEvent = (_) => true;

  DrawingLayer get layer => layers[layerIndex];

  TextLayer selectedText;

  String _mode;
  String get mode => _mode;
  set mode(String mode) {
    _mode = mode;
    _container.setAttribute('mode', mode);
    _onTextDeselect();
  }

  ImageElement get backgroundImageElement => _img;
  num get naturalWidth => _img.naturalWidth;
  num get naturalHeight => _img.naturalHeight;

  Whiteboard(
    HtmlElement container, {
    String webSocketPrefix = '',
    this.textControlsWrapMin = 0,
  }) : _container = container {
    _initDom();
    _initTextControls();
    _initCursorControls();
    _initKeyListener();
    mode = modeDraw;
    pin = PinLayer(this);
    socket
      ..whiteboard = this
      ..prefix = webSocketPrefix;
  }

  Future<void> loadFromBlob(Blob blob) async {
    var bytes = await blobToBytes(blob);
    loadFromBytes(BinaryReader(bytes.buffer));
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    clear(sendEvent: false, deleteLayers: true);
    var layerCount = reader.readUInt8();
    for (var i = 0; i < layerCount; i++) {
      layers.add(DrawingLayer(this)..loadFromBytes(reader));
    }

    var textCount = reader.readUInt8();
    for (var i = 0; i < textCount; i++) {
      texts.add(TextLayer(this)..loadFromBytes(reader));
    }

    pin.loadFromBytes(reader);
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

  @override
  void clear({bool sendEvent = true, bool deleteLayers = false}) {
    for (var t in texts) {
      (t as Layer).dispose();
    }
    texts.clear();
    pin.visible = false;
    history.erase();

    if (deleteLayers) {
      for (var l in layers) {
        (l as Layer).dispose();
      }
      layers.clear();
    } else {
      for (var l in layers) {
        (l as DrawingLayer).onClear();
      }
    }

    if (sendEvent) {
      socket.send(BinaryEvent(7)..writeBool(deleteLayers));
    }
  }

  Future<void> changeBackground(String src) async {
    _img.setAttribute('src', src);
    await _img.onLoad.first;
    _background.href.baseVal = src;
    updateScaling();
  }

  /// Resizes the SVG viewbox to optimal size.
  /// This is run on every window resize event
  /// but may be called at any time.
  void updateScaling() {
    var w = _container.clientWidth;
    var h = _container.clientHeight;
    var zoomX = w / _img.naturalWidth;
    var zoomY = h / _img.naturalHeight;
    _zoomCorrection = min(zoomX, zoomY);

    if (root.viewBox.baseVal == null) {
      root.setAttribute('viewBox', '0 0 100 100');
    }

    root.viewBox.baseVal
      ..width = w / _zoomCorrection
      ..height = h / _zoomCorrection;
  }

  /// Draws the current background image and strokes from all layers
  /// to the context of [canvas] in full scale.
  /// This method does not support drawing text items or whiteboard pins.
  void drawToCanvas(CanvasElement canvas) {
    var ctx = canvas.context2D;
    ctx.drawImage(_img, 0, 0);

    for (var layer in layers) {
      for (var stroke in layer.strokes) {
        ctx.strokeStyle = stroke.stroke;
        ctx.lineWidth = stroke.strokeWidthNum;
        ctx.stroke(Path2D(stroke.toData()));
      }
    }
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
        ..append(_fontSizeInput..min = '5')
        ..append(textRemoveButton
          ..text = 'Remove'
          ..onClick.listen((_) => _removeSelectedText())));

    root
      ..width.baseVal.valueAsString = '100%'
      ..height.baseVal.valueAsString = '100%'
      ..append(_background);
    _container
      ..append(root)
      ..append(_textControls);
    window.onResize.listen((_) => updateScaling());
  }

  void _initTextControls() {
    _textInput.onInput.listen((ev) {
      selectedText?.text = _textInput.value;
    });
    _fontSizeInput.onInput.listen((ev) {
      selectedText?.fontSize = _fontSizeInput.valueAsNumber ?? defaultFontSize;
    });
  }

  static bool _isInput(Element e) => e is InputElement || e is TextAreaElement;

  void _initKeyListener() {
    window.onKeyDown.listen((ev) {
      if (captureInput && !_isInput(ev.target)) {
        switch (ev.key) {
          case 'Delete':
          case 'Backspace':
            if (mode == modePin) return (pin as PinLayer).hide();

            return _removeSelectedText();
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

  void _removeSelectedText() {
    if (selectedText != null) {
      var register = !selectedText.isCreation;
      history.perform(
        TextInstanceAction(selectedText, selectedText.position, false),
        register,
      );
      _onTextDeselect();
    }
  }

  void _onTextSelect(TextLayer text) {
    selectedText = text..focused = true;
    _textInput
      ..value = text.text
      ..disabled = false;
    _fontSizeInput
      ..valueAsNumber = text.fontSize
      ..disabled = false;

    var p = forceDoublePoint(text.position) * _zoomCorrection;

    // Check if text controls should appear below the text
    var shouldWrap = p.y - textControlsWrapMin <= _textControls.clientHeight;

    if (shouldWrap) {
      p = Point(p.x, p.y + text.fontSize * text.text.split('\n').length);
    }

    _textControls
      ..style.left = '${p.x}px'
      ..style.top = '${p.y}px'
      ..classes.toggle('display-below', shouldWrap)
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
      Point<int> fixedPoint(T ev) =>
          forceIntPoint(evToPoint(ev) * (1 / _zoomCorrection));

      startEvent.listen((ev) async {
        if (!captureInput ||
            _isInput(ev.target) ||
            !ev.path.any((e) => e == root) ||
            !useStartEvent(ev)) return;

        Layer layer = mode == modeDraw ? this.layer : (pin as PinLayer);

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

        var action = Completer<Action>();

        var first = fixedPoint(ev);
        if (eraser && mode == modeDraw && eraseAcrossLayers) {
          // Erase across layers
          var strokesBefore = <DrawingLayer, List<Stroke>>{};

          for (var l in layers) {
            strokesBefore[l] = List.from(l.strokes);
          }

          var combinedEraseStream = Future.wait(layers.map((l) =>
              (l as DrawingLayer)
                  .handleEraseStream(first, moveStreamCtrl.stream)));

          unawaited(combinedEraseStream.then((actions) {
            var combinedErased = <DrawnStroke>[];

            for (StrokeAction a in actions) {
              if (a != null) {
                combinedErased
                    .addAll(a.list.map((s) => DrawnStroke(a.layer, s)));
              }
            }

            var combinedAction =
                StrokeAcrossAction(false, combinedErased, strokesBefore);
            action.complete(combinedErased.isEmpty ? null : combinedAction);
          }));
        } else {
          // Other mouse actions
          unawaited(layer.onMouseDown(first, moveStreamCtrl.stream).then((a) {
            action.complete(a);
          }));
        }

        await endEvent.first;
        await moveStreamCtrl.close();
        moveStreamCtrl = null;

        if (mode == modeText && layer.layerEl.isConnected) {
          _onTextSelect(layer);
        }

        history.registerDoneAction(await action.future);
      });

      moveEvent.listen((ev) {
        if (moveStreamCtrl != null &&
            !(mode == modeText &&
                !(ev as dynamic).path.any((e) => e == root))) {
          moveStreamCtrl.add(fixedPoint(ev));
        }
      });
    }

    listenToCursorEvents<MouseEvent>(
        (ev) => ev.page - _container.documentOffset,
        root.onMouseDown,
        window.onMouseMove,
        window.onMouseUp);

    listenToCursorEvents<TouchEvent>(
        (ev) => ev.targetTouches[0].page - _container.documentOffset,
        root.onTouchStart,
        window.onTouchMove,
        window.onTouchEnd);
  }
}

import 'dart:async';
import 'dart:math';
import 'dart:svg' as svg;

import '../binary.dart';
import '../communication/binary_event.dart';
import '../communication/event_type.dart';
import '../history.dart';
import '../whiteboard.dart';
import 'layer.dart';
import 'text_data.dart';

class TextLayer extends Layer with TextData {
  svg.TextElement get textElement => layerEl as svg.TextElement;

  bool _focused = false;
  bool get focused => _focused;
  set focused(bool focused) {
    if (textElement.isConnected == false) return;

    _focused = focused;
    if (focused) {
      _isCreation = false;
      _bufferedText = text;
      _bufferedFontSize = fontSize;
    } else if (_bufferedText != null && _bufferedFontSize != null) {
      text = text.trim();

      if (text.isEmpty) {
        text = _bufferedText!;
        fontSize = _bufferedFontSize!;
      } else if (text != _bufferedText || fontSize != _bufferedFontSize) {
        canvas.history.registerDoneAction(TextUpdateAction(
            this, _bufferedText!, text, _bufferedFontSize!, fontSize));
      }
    }
  }

  String? _bufferedText;
  int? _bufferedFontSize;

  @override
  set fontSize(int fontSize) {
    super.fontSize = max(5, fontSize);
    textElement.style.fontSize = '${super.fontSize}px';
  }

  @override
  set text(String text) {
    super.text = text;
    textElement.children.clear();

    // Split text into separate tspan's because SVG doesn't
    // support multiline text '-'
    var lines = text.split('\n');
    textElement.text = lines.first;

    textElement.children.addAll(lines.sublist(1).map((line) {
      var empty = line.isEmpty;

      var span = svg.TSpanElement()
        // Empty lines wouldn't be displayed at all
        ..text = empty ? line = '_' : line
        ..x!.baseVal!.appendItem(_zeroLength)
        ..dy!
            .baseVal!
            .appendItem(canvas.root.createSvgLength()..valueAsString = '1.2em');

      if (empty) {
        span.style.visibility = 'hidden';
      }

      return span;
    }));
  }

  @override
  set position(Point position) {
    var p = Point<int>(position.x.toInt(), max(0, position.y.toInt()));

    super.position = p;
    textElement
      ..x!.baseVal![0].value = p.x
      ..y!.baseVal![0].value = p.y;
    textElement.children
        .whereType<svg.TSpanElement>()
        .forEach((span) => span.x!.baseVal![0].value = p.x);
  }

  late svg.Length _zeroLength;
  bool _isCreation = true;

  TextLayer(Whiteboard canvas) : super(canvas, svg.TextElement()) {
    _zeroLength = canvas.root.createSvgLength()..value = 0;
    textElement
      ..x!.baseVal!.appendItem(_zeroLength)
      ..y!.baseVal!.appendItem(_zeroLength)
      ..text = ''
      ..setAttribute('paint-order', 'stroke')
      ..setAttribute('text-anchor', 'middle')
      ..setAttribute('dominant-baseline', 'central');
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    super.loadFromBytes(reader);
    _isCreation = false;
  }

  bool get isCreation => _isCreation;

  @override
  Future<Action?> onMouseDown(Point first, Stream<Point> stream) async {
    var creation = isCreation;
    var completer = Completer();

    var startPos = position;
    stream.listen((p) {
      position = Point<num>(startPos.x, startPos.y) + (p - first);
    }, onDone: () => completer.complete(position));

    var endPos = await completer.future;

    if (textElement.isConnected == false) {
      // Text element was deleted while dragging
      return null;
    }

    if (creation) {
      return TextInstanceAction(this, endPos, true);
    }
    return TextMoveAction(this, startPos, endPos);
  }
}

mixin TextAction on Action {
  TextLayer get layer;
}

class TextMoveAction extends Action with TextAction {
  final TextLayer _layer;
  final Point<int> posA;
  final Point<int> posB;

  @override
  TextLayer get layer => _layer;

  TextMoveAction(TextLayer layer, this.posA, this.posB) : _layer = layer;

  @override
  void doAction() {
    layer.position = posB;
    _send(true);
  }

  @override
  void undoAction() {
    layer.position = posA;
    _send(false);
  }

  @override
  void onSilentRegister() => _send(true);

  void _send(bool forward) {
    if (userCreated) {
      layer.canvas.socket.send(
          BinaryEvent(EventType.textUpdatePosition, textLayer: layer)
            ..writePoint(forward ? posB : posA));
    }
  }
}

class TextUpdateAction extends Action with TextAction {
  final TextLayer _layer;
  final String textA;
  final String textB;
  final int sizeA;
  final int sizeB;

  @override
  TextLayer get layer => _layer;

  TextUpdateAction(
    TextLayer layer,
    this.textA,
    this.textB,
    this.sizeA,
    this.sizeB,
  ) : _layer = layer;

  @override
  void doAction() {
    layer.text = textB;
    layer.fontSize = sizeB;
    _send(true);
  }

  @override
  void undoAction() {
    layer.text = textA;
    layer.fontSize = sizeA;
    _send(false);
  }

  @override
  void onSilentRegister() {
    _send(true);
  }

  void _send(bool forward) {
    if (userCreated) {
      layer.canvas.socket.send(BinaryEvent(
        EventType.textUpdateText,
        textLayer: layer,
      )
        ..writeUInt8(forward ? sizeB : sizeA)
        ..writeString(forward ? textB : textA));
    }
  }
}

class TextInstanceAction extends SingleAddRemoveAction with TextAction {
  final TextLayer _layer;
  final Point<int> position;

  @override
  TextLayer get layer => _layer;

  TextInstanceAction(TextLayer layer, this.position, bool forward)
      : _layer = layer,
        super(forward);

  @override
  void create() {
    layer.canvas.root.append(layer.layerEl);
    layer.canvas.texts.add(layer..position = position);
    _sendCreate();
  }

  @override
  void delete() {
    _sendDelete();
    layer.dispose();
    layer.canvas.texts.remove(layer);
  }

  @override
  void onSilentRegister() {
    forward ? _sendCreate() : _sendDelete();
  }

  void _sendCreate() {
    if (userCreated) {
      layer.canvas.socket.send(BinaryEvent(EventType.textCreate,
          textLayer: layer, layerInclude: false)
        ..writePoint(position)
        ..writeUInt8(layer.fontSize)
        ..writeString(layer.text));
    }
  }

  void _sendDelete() {
    if (userCreated) {
      layer.canvas.socket
          .send(BinaryEvent(EventType.textRemove, textLayer: layer));
    }
  }
}

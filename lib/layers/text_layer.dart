import 'dart:async';
import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/history.dart';
import 'package:web_whiteboard/layers/text_data.dart';
import 'package:web_whiteboard/util.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/whiteboard.dart';

class TextLayer extends Layer with TextData {
  svg.TextElement get textElement => layerEl;

  bool _focused;
  bool get focused => _focused;
  set focused(bool focused) {
    _focused = focused;
    if (focused) {
      _bufferedText = text;
      _bufferedFontSize = fontSize;
    } else {
      if (text != _bufferedText || fontSize != _bufferedFontSize) {
        canvas.history.registerDoneAction(TextUpdateAction(
            this, _bufferedText, text, _bufferedFontSize, fontSize));
      }
    }
  }

  String _bufferedText;
  int _bufferedFontSize;

  @override
  set fontSize(int fontSize) {
    super.fontSize = fontSize;
    textElement.style.fontSize = '${fontSize}px';
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
        ..x.baseVal.appendItem(_zeroLength)
        ..dy
            .baseVal
            .appendItem(canvas.root.createSvgLength()..valueAsString = '1.2em');

      if (empty) {
        span.style.visibility = 'hidden';
      }

      return span;
    }));
  }

  @override
  set position(Point position) {
    var p = forceIntPoint(position);
    super.position = p;
    textElement
      ..x.baseVal[0].value = p.x
      ..y.baseVal[0].value = p.y;
    textElement.children
        .whereType<svg.TSpanElement>()
        .forEach((span) => span.x.baseVal[0].value = p.x);
  }

  svg.Length _zeroLength;

  TextLayer(Whiteboard canvas) : super(canvas, svg.TextElement()) {
    _zeroLength = canvas.root.createSvgLength()..value = 0;
    textElement
      ..x.baseVal.appendItem(_zeroLength)
      ..y.baseVal.appendItem(_zeroLength)
      ..text = text
      ..setAttribute('paint-order', 'stroke')
      ..setAttribute('text-anchor', 'middle')
      ..setAttribute('dominant-baseline', 'central');
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    super.loadFromBytes(reader);
    _bufferedText = text; // important for determining creation state at [1]
  }

  @override
  Future<Action> onMouseDown(Point first, Stream<Point> stream) async {
    var isCreation = _bufferedText == null; // [1]
    var completer = Completer();

    var startPos = position;
    stream.listen((p) {
      position = startPos + (p - first);
    }, onDone: () => completer.complete(position));

    var endPos = await completer.future;
    if (isCreation) {
      return TextInstanceAction(this, true);
    }
    return CustomAction(() => position = endPos, () => position = startPos);
  }
}

class TextUpdateAction extends Action {
  final TextLayer layer;
  final String textA;
  final String textB;
  final int sizeA;
  final int sizeB;

  TextUpdateAction(this.layer, this.textA, this.textB, this.sizeA, this.sizeB);

  @override
  void doAction() {
    layer.text = textB;
    layer.fontSize = sizeB;
  }

  @override
  void undoAction() {
    layer.text = textA;
    layer.fontSize = sizeA;
  }
}

class TextInstanceAction extends SingleAddRemoveAction {
  final TextLayer layer;

  TextInstanceAction(this.layer, bool forward) : super(forward);

  @override
  void create() {
    layer.canvas.root.append(layer.layerEl);
    layer.canvas.texts.add(layer);
  }

  @override
  void delete() {
    layer.dispose();
    layer.canvas.texts.remove(layer);
  }

  @override
  void onExecuted(bool forward) {}
}

import 'dart:async';
import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_whiteboard/history.dart';
import 'package:web_whiteboard/layers/text_data.dart';
import 'package:web_whiteboard/util.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/whiteboard.dart';

class TextLayer extends Layer with TextData {
  svg.TextElement get textElement => layerEl;

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
  Future<Action> onMouseDown(Point first, Stream<Point> stream) async {
    var completer = Completer();

    var startPos = position;
    stream.listen((p) {
      position = startPos + (p - first);
    }, onDone: () => completer.complete(position));

    var endPos = await completer.future;
    return CustomAction(() => position = endPos, () => position = startPos);
  }
}

import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_drawing/binary.dart';
import 'package:web_drawing/layers/layer.dart';
import 'package:web_drawing/web_drawing.dart';

class TextLayer extends Layer {
  svg.TextElement textElement;

  String _text;
  String get text => _text;
  set text(String text) {
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
            .appendItem(layerEl.createSvgLength()..valueAsString = '1.2em');

      if (empty) {
        span.style.visibility = 'hidden';
      }

      return span;
    }));

    _text = text;
  }

  CssStyleDeclaration get style => layerEl.style;

  svg.Length _zeroLength;

  TextLayer(DrawingCanvas canvas) : super(canvas) {
    _zeroLength = layerEl.createSvgLength()..value = 0;
    style
      ..fontWeight = 'bold'
      ..fontSize = '24px'
      ..textShadow = '0 0 2px #fff7';
  }

  @override
  void onMouseDown(Point first, Stream<Point> stream) {
    textElement ??= svg.TextElement()
      ..x.baseVal.appendItem(_zeroLength)
      ..y.baseVal.appendItem(_zeroLength)
      ..text = 'Text'
      ..setAttribute('text-anchor', 'middle')
      ..setAttribute('dominant-baseline', 'central')
      ..setAttribute('fill', '#111');
    layerEl.append(textElement);

    void move(Point p) {
      textElement
        ..x.baseVal[0].value = p.x
        ..y.baseVal[0].value = p.y;
      textElement.children
          .whereType<svg.TSpanElement>()
          .forEach((span) => span.x.baseVal[0].value = p.x);
    }

    move(first);
    stream.listen((p) => move(p));
  }

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.addUInt8(1); // Layer type
    writer.addString(text);
    writer.addInt32(textElement.x.baseVal[0].value);
    writer.addInt32(textElement.y.baseVal[0].value);
  }
}

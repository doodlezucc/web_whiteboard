import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_drawing/binary.dart';
import 'package:web_drawing/font_styleable.dart';
import 'package:web_drawing/layers/layer.dart';
import 'package:web_drawing/web_drawing.dart';

class TextLayer extends Layer {
  svg.TextElement get textElement => layerEl;

  String _text = 'Text';
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
            .appendItem(canvas.root.createSvgLength()..valueAsString = '1.2em');

      if (empty) {
        span.style.visibility = 'hidden';
      }

      return span;
    }));

    _text = text;
  }

  svg.Length _zeroLength;

  TextLayer(DrawingCanvas canvas) : super(canvas, svg.TextElement()) {
    _zeroLength = canvas.root.createSvgLength()..value = 0;
    textElement
      ..x.baseVal.appendItem(_zeroLength)
      ..y.baseVal.appendItem(_zeroLength)
      ..text = _text
      ..setAttribute('paint-order', 'stroke')
      ..setAttribute('text-anchor', 'middle')
      ..setAttribute('dominant-baseline', 'central');
  }

  @override
  void onMouseDown(Point first, Stream<Point> stream) {
    move(first);
    stream.listen((p) => move(p));
  }

  void move(Point p) {
    textElement
      ..x.baseVal[0].value = p.x
      ..y.baseVal[0].value = p.y;
    textElement.children
        .whereType<svg.TSpanElement>()
        .forEach((span) => span.x.baseVal[0].value = p.x);
  }

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.writeUInt8(layerType); // Layer type
    writer.writePoint(
        Point(textElement.x.baseVal[0].value, textElement.y.baseVal[0].value));
    writer.writeString(text);
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    move(reader.readPoint());
    text = reader.readString();
  }

  @override
  int get layerType => 1;
}

class StylizedTextLayer extends TextLayer with FontStyleable {
  StylizedTextLayer(DrawingCanvas canvas) : super(canvas);

  @override
  CssStyleDeclaration get style => layerEl.style;

  @override
  int get layerType => 2;

  @override
  void writeToBytes(BinaryWriter writer) {
    super.writeToBytes(writer);
    writeStyleToBytes(writer);
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    super.loadFromBytes(reader);
    readStyleFromBytes(reader);
  }
}

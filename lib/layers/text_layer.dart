import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/whiteboard.dart';

class TextLayer extends Layer {
  svg.TextElement get textElement => layerEl;

  String _fontSize = '';
  String get fontSize => _fontSize;
  set fontSize(String fontSize) {
    textElement.style.fontSize = fontSize.isNotEmpty ? fontSize : null;
    _fontSize = fontSize;
  }

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

  Point<int> _position = Point(0, 0);
  Point<int> get position => _position;
  set position(Point position) {
    var p = Point<int>(position.x, position.y);
    _position = p;
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
      ..text = _text
      ..setAttribute('paint-order', 'stroke')
      ..setAttribute('text-anchor', 'middle')
      ..setAttribute('dominant-baseline', 'central');
  }

  @override
  void onMouseDown(Point first, Stream<Point> stream) {
    position = first;
    stream.listen((p) => position = p);
  }

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.writeUInt8(layerType); // Layer type
    writer.writePoint(position);
    writer.writeString(fontSize);
    writer.writeString(text);
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    position = reader.readPoint();
    fontSize = reader.readString();
    text = reader.readString();
  }

  @override
  int get layerType => 1;
}

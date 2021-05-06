import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_drawing/layers/layer.dart';
import 'package:web_drawing/web_drawing.dart';

class TextLayer extends Layer {
  svg.TextElement textElement;

  String get text => textElement?.text;
  set text(String text) => textElement.text = text;

  CssStyleDeclaration get style => layerEl.style;

  svg.Length _zeroLength;

  TextLayer(DrawingCanvas canvas) : super(canvas) {
    _zeroLength = layerEl.createSvgLength()..value = 0;
    style
      ..fontWeight = 'bold'
      ..fontSize = '20px'
      ..textShadow = '0 0 2px #fff';
  }

  @override
  void onMouseDown(Point first, Stream<Point> stream) {
    textElement ??= svg.TextElement()
      ..x.baseVal.appendItem(_zeroLength)
      ..y.baseVal.appendItem(_zeroLength)
      ..text = 'Text'
      ..setAttribute('text-anchor', 'middle')
      ..setAttribute('fill', '#111');
    layerEl.append(textElement);

    void move(Point p) {
      textElement
        ..x.baseVal[0].value = p.x
        ..y.baseVal[0].value = p.y;
    }

    move(first);
    stream.listen((p) => move(p));
  }
}

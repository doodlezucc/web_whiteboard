import 'dart:html';
import 'dart:svg' as svg;

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/whiteboard.dart';

abstract class Layer {
  final Whiteboard canvas;
  final svg.SvgElement layerEl;

  Layer(this.canvas, this.layerEl) {
    layerEl.style.position = 'absolute';
    canvas.root.append(layerEl);
  }

  void onMouseDown(Point first, Stream<Point> moveStream);

  void dispose() {
    layerEl.remove();
  }

  void writeToBytes(BinaryWriter writer);
  void loadFromBytes(BinaryReader reader);
}

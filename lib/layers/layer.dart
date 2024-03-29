import 'dart:html';
import 'dart:svg' as svg;

import '../binary.dart';
import '../history.dart';
import '../whiteboard.dart';

abstract class Layer {
  final Whiteboard canvas;
  final svg.SvgElement layerEl;

  Layer(this.canvas, this.layerEl) {
    layerEl.style.position = 'absolute';
    canvas.root.append(layerEl);
  }

  Future<Action?> onMouseDown(Point<int> first, Stream<Point<int>> moveStream);

  void dispose() {
    layerEl.remove();
  }

  void writeToBytes(BinaryWriter writer);
  void loadFromBytes(BinaryReader reader);
}

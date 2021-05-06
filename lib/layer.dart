import 'package:web_drawing/web_drawing.dart';

abstract class Layer {
  final DrawingCanvas canvas;
  bool visible = true;

  Layer(this.canvas);
}

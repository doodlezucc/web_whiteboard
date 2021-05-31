import 'package:web_whiteboard/layers/drawing_layer.dart';
import 'package:web_whiteboard/stroke.dart';

class DrawnStroke {
  final DrawingLayer layer;
  final Stroke stroke;

  DrawnStroke(this.layer, this.stroke);
}

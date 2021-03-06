import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/drawing_layer.dart';
import 'package:web_whiteboard/layers/text_layer.dart';
import 'package:web_whiteboard/whiteboard.dart';

class BinaryEvent extends BinaryWriter {
  final int id;
  final EventContext context;

  BinaryEvent(
    this.id, {
    DrawingLayer drawingLayer,
    TextLayer textLayer,
    bool layerInclude = true,
  }) : context =
            EventContext(drawingLayer: drawingLayer, textLayer: textLayer) {
    writeUInt8(id);

    if (layerInclude) {
      if (drawingLayer != null) {
        _writeLayerIndex();
      } else if (textLayer != null) {
        _writeTextIndex();
      }
    }
  }

  void _writeLayerIndex() => writeUInt8(context.drawingLayer.indexInWhiteboard);
  void _writeTextIndex() =>
      writeUInt8(context.whiteboard.texts.indexOf(context.textLayer));
}

class EventContext {
  final Whiteboard whiteboard;
  final DrawingLayer drawingLayer;
  final TextLayer textLayer;

  EventContext({this.drawingLayer, this.textLayer})
      : whiteboard = drawingLayer?.canvas ?? textLayer?.canvas;
}

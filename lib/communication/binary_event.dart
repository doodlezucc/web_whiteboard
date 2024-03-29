import '../binary.dart';
import '../layers/drawing_layer.dart';
import '../layers/text_layer.dart';
import '../whiteboard.dart';

class BinaryEvent extends BinaryWriter {
  final int eventType;
  final EventContext context;

  BinaryEvent(
    this.eventType, {
    DrawingLayer? drawingLayer,
    TextLayer? textLayer,
    bool layerInclude = true,
  }) : context =
            EventContext(drawingLayer: drawingLayer, textLayer: textLayer) {
    writeUInt8(eventType);

    if (layerInclude) {
      if (drawingLayer != null) {
        _writeLayerIndex();
      } else if (textLayer != null) {
        _writeTextIndex();
      }
    }
  }

  void _writeLayerIndex() =>
      writeUInt8(context.drawingLayer!.indexInWhiteboard);
  void _writeTextIndex() =>
      writeUInt8(context.whiteboard!.texts.indexOf(context.textLayer!));
}

class EventContext {
  final Whiteboard? whiteboard;
  final DrawingLayer? drawingLayer;
  final TextLayer? textLayer;

  EventContext({this.drawingLayer, this.textLayer})
      : whiteboard = drawingLayer?.canvas ?? textLayer?.canvas;
}

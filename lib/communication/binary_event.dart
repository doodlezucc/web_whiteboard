import '../binary.dart';
import '../layers/drawing_layer.dart';
import '../layers/text_layer.dart';
import '../whiteboard.dart';

class BinaryEvent extends BinaryWriter {
  final int id;
  final EventContext context;

  BinaryEvent(
    this.id, {
    DrawingLayer? drawingLayer,
    TextLayer? textLayer,
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

  void _writeLayerIndex() =>
      writeUInt8(context.drawingLayer!.indexInWhiteboard);
  void _writeTextIndex() =>
      writeUInt8(context.whiteboard.texts.indexOf(context.textLayer!));
}

class EventContext {
  late Whiteboard whiteboard;
  final DrawingLayer? drawingLayer;
  final TextLayer? textLayer;

  EventContext({this.drawingLayer, this.textLayer}) {
    if (drawingLayer == null && textLayer == null) {
      throw 'Supply either a drawing layer or a text layer (or both)';
    }

    whiteboard = (drawingLayer?.canvas ?? textLayer?.canvas)!;
  }
}

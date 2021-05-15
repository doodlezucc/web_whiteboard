import 'dart:async';

import 'dart:typed_data';

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/drawing_layer.dart';
import 'package:web_whiteboard/layers/text_layer.dart';
import 'package:web_whiteboard/stroke.dart';
import 'package:web_whiteboard/whiteboard.dart';

class WhiteboardSocket {
  Whiteboard whiteboard;
  final _controller = StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get sendStream => _controller.stream;

  WhiteboardSocket();

  void send(BinaryEvent event) {
    var bytes = event.takeBytes();
    print(bytes);
    _controller.sink.add(bytes);
  }

  bool handleEvent(Uint8List bytes) {
    var reader = BinaryReader(bytes.buffer);

    DrawingLayer getLayer() => whiteboard.layers[reader.readUInt8()];
    TextLayer getText() {
      var i = reader.readUInt8();
      print(i);
      return whiteboard.texts[i];
    }

    switch (reader.readUInt8()) {
      case 0:
        var layer = getLayer();
        var strokes = <Stroke>[];
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          strokes.add(Stroke()..loadFromBytes(reader));
        }
        whiteboard.history.perform(
            StrokeAction(layer, true, strokes, null)..userCreated = false,
            false);
        return true;

      case 1:
        var layer = getLayer();
        var toRemove = <Stroke>[];
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          var index = reader.readUInt8();
          print('$i | $index');
          toRemove.add(layer.strokes[index]);
        }
        whiteboard.history.perform(
            StrokeAction(layer, false, toRemove, null)..userCreated = false,
            false);
        return true;

      case 2:
        var position = reader.readPoint();
        var fontSize = reader.readUInt8();
        var text = reader.readString();
        whiteboard.history.perform(
            TextInstanceAction(
                TextLayer(whiteboard)
                  ..fontSize = fontSize
                  ..text = text,
                position,
                true)
              ..userCreated = false,
            false);
        return true;

      case 3:
        var layer = getText();
        var fontSize = reader.readUInt8();
        var text = reader.readString();
        whiteboard.history.perform(
            TextUpdateAction(layer, null, text, null, fontSize)
              ..userCreated = false,
            false);
        return true;

      case 4:
        whiteboard.history.perform(
            TextMoveAction(getText(), null, reader.readPoint())
              ..userCreated = false,
            false);
        return true;

      case 5:
        whiteboard.history.perform(
            TextInstanceAction(getText(), null, false)..userCreated = false,
            false);
        return true;
    }

    return false;
  }
}

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
        writeLayerIndex();
      } else if (textLayer != null) {
        writeTextIndex();
      }
    }
  }

  void writeLayerIndex() =>
      writeUInt8(context.whiteboard.layers.indexOf(context.drawingLayer));
  void writeTextIndex() =>
      writeUInt8(context.whiteboard.texts.indexOf(context.textLayer));
}

class EventContext {
  final Whiteboard whiteboard;
  final DrawingLayer drawingLayer;
  final TextLayer textLayer;

  EventContext({this.drawingLayer, this.textLayer})
      : whiteboard = drawingLayer?.canvas ?? textLayer?.canvas;
}

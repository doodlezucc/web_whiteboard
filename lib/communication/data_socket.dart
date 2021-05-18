import 'dart:typed_data';

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/drawing_data.dart';
import 'package:web_whiteboard/layers/text_data.dart';
import 'package:web_whiteboard/stroke.dart';
import 'package:web_whiteboard/whiteboard_data.dart';

class WhiteboardDataSocket {
  final WhiteboardData whiteboard;

  WhiteboardDataSocket(this.whiteboard);

  bool handleEvent(data) {
    var bytes = Uint8List.fromList(data);
    var reader = BinaryReader.fromList(bytes);

    DrawingData getLayer() => whiteboard.layers[reader.readUInt8()];
    TextData getText() => whiteboard.texts[reader.readUInt8()];

    switch (reader.readUInt8()) {
      case 0:
        var layer = getLayer();
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          layer.strokes.add(Stroke()..loadFromBytes(reader));
        }
        return true;

      case 1:
        var layer = getLayer();
        var toRemove = <Stroke>[];
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          var index = reader.readUInt8();
          toRemove.add(layer.strokes[index]);
        }
        toRemove.forEach((s) => layer.strokes.remove(s));
        return true;

      case 2:
        whiteboard.texts.add(TextData()
          ..position = reader.readPoint()
          ..fontSize = reader.readUInt8()
          ..text = reader.readString());
        return true;

      case 3:
        getText()
          ..fontSize = reader.readUInt8()
          ..text = reader.readString();
        return true;

      case 4:
        getText().position = reader.readPoint();
        return true;

      case 5:
        whiteboard.texts.remove(getText());
        return true;
    }

    return false;
  }
}

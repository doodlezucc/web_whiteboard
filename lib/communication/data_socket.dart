import 'dart:typed_data';

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/communication/socket_base.dart';
import 'package:web_whiteboard/layers/drawing_data.dart';
import 'package:web_whiteboard/layers/text_data.dart';
import 'package:web_whiteboard/stroke.dart';
import 'package:web_whiteboard/whiteboard_data.dart';

class WhiteboardDataSocket extends SocketBase {
  final WhiteboardData whiteboard;

  /// `prefix` may define a string prepended to incoming and outgoing events.
  /// Keep it unique so whiteboard messages don't mix up with other traffic
  /// on your websocket.
  WhiteboardDataSocket(this.whiteboard, {String prefix = ''}) : super(prefix);

  bool handleEvent(List<int> data) {
    if (!matchPrefix(data)) return false;

    var bytes = Uint8List.fromList(data.sublist(prefixBytes.length));
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

      case 6:
        whiteboard.pin.loadFromBytes(reader);
        return true;

      case 7:
        whiteboard.clear(deleteLayers: reader.readBool());
        return true;

      case 8:
        var strokeCount = reader.readUInt8();
        for (var i = 0; i < strokeCount; i++) {
          getLayer().strokes.add(Stroke()..loadFromBytes(reader));
        }
        return true;

      case 9:
        var strokeCount = reader.readUInt8();
        var toRemove = <DrawingData, List<Stroke>>{};
        for (var i = 0; i < strokeCount; i++) {
          var layer = getLayer();
          var index = reader.readUInt8();
          toRemove.putIfAbsent(layer, () => []).add(layer.strokes[index]);
        }
        toRemove.forEach((layer, strokes) {
          strokes.forEach((s) {
            layer.strokes.remove(s);
          });
        });
        return true;
    }

    return false;
  }
}

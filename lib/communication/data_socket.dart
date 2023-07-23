import 'dart:typed_data';

import '../binary.dart';
import '../layers/drawing_data.dart';
import '../layers/text_data.dart';
import '../stroke.dart';
import '../whiteboard_data.dart';
import 'event_type.dart';
import 'socket_base.dart';

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

    print(data);

    switch (reader.readUInt8()) {
      case EventType.strokeCreate:
        var layer = getLayer();
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          layer.strokes.add(Stroke()..loadFromBytes(reader));
        }
        return true;

      case EventType.strokeRemove:
        var layer = getLayer();
        var toRemove = <Stroke>[];
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          var index = reader.readUInt8();
          toRemove.add(layer.strokes[index]);
        }
        toRemove.forEach((s) => layer.strokes.remove(s));
        return true;

      case EventType.textCreate:
        whiteboard.texts.add(TextData()
          ..position = reader.readPoint()
          ..fontSize = reader.readUInt8()
          ..text = reader.readString());
        return true;

      case EventType.textUpdateText:
        getText()
          ..fontSize = reader.readUInt8()
          ..text = reader.readString();
        return true;

      case EventType.textUpdatePosition:
        getText().position = reader.readPoint();
        return true;

      case EventType.textRemove:
        whiteboard.texts.remove(getText());
        return true;

      case EventType.pinMove:
        whiteboard.pin.loadFromBytes(reader);
        return true;

      case EventType.clear:
        whiteboard.clear(deleteLayers: reader.readBool());
        return true;

      case EventType.strokeMultipleCreate:
        var strokeCount = reader.readUInt8();
        for (var i = 0; i < strokeCount; i++) {
          getLayer().strokes.add(Stroke()..loadFromBytes(reader));
        }
        return true;

      case EventType.strokeMultipleRemove:
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

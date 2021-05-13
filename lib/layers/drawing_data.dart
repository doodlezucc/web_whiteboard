import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/stroke.dart';

class DrawingData implements Serializable {
  List<Stroke> strokes = [];

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.writeUInt16(strokes.length);
    for (var data in strokes) {
      data.writeToBytes(writer);
    }
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    var pathCount = reader.readUInt16();
    for (var i = 0; i < pathCount; i++) {
      var data = Stroke()..loadFromBytes(reader);
      strokes.add(data);
    }
  }
}

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/drawing_data.dart';
import 'package:web_whiteboard/layers/text_data.dart';

class WhiteboardData implements Serializable {
  final layers = <DrawingData>[];
  final texts = <TextData>[];

  @override
  void loadFromBytes(BinaryReader reader) {
    var layerCount = reader.readUInt8();
    for (var i = 0; i < layerCount; i++) {
      layers.add(DrawingData()..loadFromBytes(reader));
    }

    var textCount = reader.readUInt8();
    for (var i = 0; i < textCount; i++) {
      texts.add(TextData()..loadFromBytes(reader));
    }
  }

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.writeUInt8(layers.length);
    for (var layer in layers) {
      layer.writeToBytes(writer);
    }
    writer.writeUInt8(texts.length);
    for (var text in texts) {
      text.writeToBytes(writer);
    }
  }
}

import 'binary.dart';
import 'layers/drawing_data.dart';
import 'layers/pin_data.dart';
import 'layers/text_data.dart';
import 'whiteboard_base.dart';

class WhiteboardData extends WhiteboardBase<DrawingData, TextData, PinData> {
  final PinData pin = PinData();

  @override
  void loadFromBytes(BinaryReader reader) {
    layers.clear();
    texts.clear();
    var layerCount = reader.readUInt8();
    for (var i = 0; i < layerCount; i++) {
      layers.add(DrawingData()..loadFromBytes(reader));
    }

    var textCount = reader.readUInt8();
    for (var i = 0; i < textCount; i++) {
      texts.add(TextData()..loadFromBytes(reader));
    }

    pin.loadFromBytes(reader);
  }
}

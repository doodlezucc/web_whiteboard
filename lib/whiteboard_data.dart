import 'dart:typed_data';

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/layers/drawing_data.dart';
import 'package:web_whiteboard/layers/pin_data.dart';
import 'package:web_whiteboard/layers/text_data.dart';

class WhiteboardData implements Serializable {
  final layers = <DrawingData>[];
  final texts = <TextData>[];
  PinData pin = PinData();

  /// Returns true if the whiteboard doesn't contain layers.
  bool get isEmpty => layers.isEmpty && texts.isEmpty && !pin.visible;

  /// Returns true if every layer is empty.
  bool get isClear =>
      texts.isEmpty &&
      !pin.visible &&
      layers.every((layer) => layer.strokes.isEmpty);

  void clear({bool deleteLayers = false}) {
    if (deleteLayers) {
      layers.clear();
    } else {
      for (var l in layers) {
        l.strokes.clear();
      }
    }

    texts.clear();
    pin.visible = false;
  }

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
    pin.writeToBytes(writer);
  }

  void fromBytes(Uint8List bytes) => loadFromBytes(BinaryReader(bytes.buffer));

  Uint8List toBytes() {
    var writer = BinaryWriter();
    writeToBytes(writer);
    return writer.takeBytes();
  }
}

import 'dart:typed_data';

import 'binary.dart';
import 'layers/drawing_data.dart';
import 'layers/pin_data.dart';
import 'layers/text_data.dart';

abstract class WhiteboardBase<DType extends DrawingData, TType extends TextData,
    PType extends PinData> implements Serializable {
  final layers = <DType>[];
  final texts = <TType>[];
  PType get pin;

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

import 'dart:math';

import '../binary.dart';

class TextData implements Serializable {
  late Point<int> position;
  late int fontSize;
  late String text;

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.writePoint(position);
    writer.writeUInt8(fontSize);
    writer.writeString(text);
  }

  @override
  void loadFromBytes(BinaryReader reader) {
    position = reader.readPoint();
    fontSize = reader.readUInt8();
    text = reader.readString();
  }
}

import 'dart:math';

import 'package:web_whiteboard/binary.dart';

class TextData implements Serializable {
  Point<int> position;
  int fontSize;
  String text;

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

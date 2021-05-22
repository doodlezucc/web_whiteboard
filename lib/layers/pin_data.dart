import 'dart:math';

import 'package:web_whiteboard/binary.dart';

class PinData implements Serializable {
  bool visible = false;
  Point<int> position = Point(0, 0);

  @override
  void loadFromBytes(BinaryReader reader) {
    visible = reader.readBool();
    position = reader.readPoint();
  }

  @override
  void writeToBytes(BinaryWriter writer) {
    writer.writeBool(visible);
    writer.writePoint(position);
  }
}

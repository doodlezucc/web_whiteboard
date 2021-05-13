import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

final _buffer = ByteData(4);

class BinaryWriter {
  final builder = BytesBuilder();

  Uint8List takeBytes() => builder.takeBytes();

  void writeUInt8(int i) => builder.addByte(i);
  void writeUInt16(int i) => builder.add([i >> 8, i]);
  void writeUInt32(int i) => builder.add([i >> 32, i >> 16, i >> 8, i]);

  void writePoint(Point<int> p) {
    writeInt16(p.x);
    writeInt16(p.y);
  }

  void writeInt16(int i) {
    _buffer.setInt16(0, i);
    builder.add(_buffer.buffer.asUint8List(0, 2));
  }

  void writeInt32(int i) {
    _buffer.setInt32(0, i);
    builder.add(_buffer.buffer.asUint8List());
  }

  void writeString(String s) {
    var bytes = utf8.encode(s);
    writeUInt16(bytes.length);
    builder.add(bytes);
  }
}

class BinaryReader {
  final ByteData data;
  int offset = 0;

  BinaryReader(ByteBuffer buffer) : data = buffer.asByteData();

  int _read(int result, int bytes) {
    offset += bytes;
    return result;
  }

  int readUInt8() => _read(data.getUint8(offset), 1);
  int readUInt16() => _read(data.getUint16(offset), 2);
  int readUInt32() => _read(data.getUint32(offset), 4);

  int readInt16() => _read(data.getInt16(offset), 2);
  int readInt32() => _read(data.getInt32(offset), 4);

  Point<int> readPoint() => Point<int>(readInt16(), readInt16());

  String readString() {
    var length = readUInt16();
    var s = utf8.decode(data.buffer.asUint8List(offset, length));
    offset += length;
    return s;
  }
}

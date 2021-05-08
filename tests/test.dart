import 'dart:math';

import 'package:test/test.dart';
import 'package:web_drawing/binary.dart';

void main(List<String> args) {
  group('Binary I/O', () {
    var src = 'Wow very cool string 😎 i sure hope it stays like this';
    var point = Point(-5000, 12000);

    var writer = BinaryWriter();
    writer.writeUInt16(505);
    writer.writeString(src);
    writer.writeUInt16(1);
    writer.writePoint(point);
    writer.writeInt32(-500000);

    var reader = BinaryReader(writer.takeBytes().buffer);

    test('UInt16 greater than 255', () {
      expect(reader.readUInt16(), 505);
    });
    test('String', () {
      expect(reader.readString(), equals(src));
    });
    test('Reading after a string', () {
      expect(reader.readUInt16(), 1);
    });
    test('Point', () {
      expect(reader.readPoint(), point);
    });
    test('Signed Int32', () {
      expect(reader.readInt32(), -500000);
    });
  });
}

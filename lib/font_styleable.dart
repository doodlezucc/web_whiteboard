import 'dart:html';

import 'package:web_drawing/binary.dart';

mixin FontStyleable {
  CssStyleDeclaration get style;

  String get fontSize => style.fontSize;
  set fontSize(String fontSize) => style.fontSize = fontSize;

  String get fontWeight => style.fontWeight;
  set fontWeight(String fontWeight) => style.fontWeight = fontWeight;

  String get fontFamily => style.fontFamily;
  set fontFamily(String fontFamily) => style.fontFamily = fontFamily;

  String get fontStyle => style.fontStyle;
  set fontStyle(String fontStyle) => style.fontStyle = fontStyle;

  String get textColor => style.getPropertyValue('fill');
  set textColor(String color) => style.setProperty('fill', color);

  String get outlineColor => style.getPropertyValue('stroke');
  set outlineColor(String color) => style.setProperty('stroke', color);

  String get outlineWidth => style.getPropertyValue('stroke-width');
  set outlineWidth(dynamic width) =>
      style.setProperty('stroke-width', '$width');

  void writeStyleToBytes(BinaryWriter writer) {
    writer.addString(fontSize);
    writer.addString(fontWeight);
    writer.addString(fontFamily);
    writer.addString(fontStyle);
    writer.addString(textColor);
    writer.addString(outlineColor);
    writer.addString(outlineWidth);
  }

  void readStyleFromBytes(BinaryReader reader) {
    fontSize = reader.readString();
    fontWeight = reader.readString();
    fontFamily = reader.readString();
    fontStyle = reader.readString();
    textColor = reader.readString();
    outlineColor = reader.readString();
    outlineWidth = reader.readString();
  }
}

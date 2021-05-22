import 'dart:async';
import 'dart:html';

import 'dart:typed_data';

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/communication/binary_event.dart';
import 'package:web_whiteboard/communication/socket_base.dart';
import 'package:web_whiteboard/layers/drawing_layer.dart';
import 'package:web_whiteboard/layers/text_layer.dart';
import 'package:web_whiteboard/stroke.dart';
import 'package:web_whiteboard/whiteboard.dart';

class WhiteboardSocket extends SocketBase {
  Whiteboard whiteboard;
  final _controller = StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get sendStream => _controller.stream;

  /// `prefix` may define a string prepended to incoming and outgoing events.
  /// Keep it unique so whiteboard messages don't mix up with other traffic
  /// on your websocket.
  WhiteboardSocket({this.whiteboard, String prefix = ''}) : super(prefix);

  void send(BinaryEvent event) {
    var bytes = Uint8List.fromList(prefixBytes + event.takeBytes());
    _controller.sink.add(bytes);
  }

  /// Returns true if `blob` starts with the socket prefix
  /// and the event was handled successfully.
  Future<bool> handleEvent(Blob blob) async {
    return handleEventBytes(await blobToBytes(blob));
  }

  bool handleEventBytes(Uint8List bytes) {
    if (!matchPrefix(bytes)) return false;

    var reader = BinaryReader(bytes.sublist(prefixBytes.length).buffer);

    DrawingLayer getLayer() => whiteboard.layers[reader.readUInt8()];
    TextLayer getText() => whiteboard.texts[reader.readUInt8()];

    switch (reader.readUInt8()) {
      case 0:
        var layer = getLayer();
        var strokes = <Stroke>[];
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          strokes.add(Stroke()..loadFromBytes(reader));
        }
        whiteboard.history.perform(
            StrokeAction(layer, true, strokes, null)..userCreated = false,
            false);
        return true;

      case 1:
        var layer = getLayer();
        var toRemove = <Stroke>[];
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          var index = reader.readUInt8();
          toRemove.add(layer.strokes[index]);
        }
        whiteboard.history.perform(
            StrokeAction(layer, false, toRemove, null)..userCreated = false,
            false);
        return true;

      case 2:
        var position = reader.readPoint();
        var fontSize = reader.readUInt8();
        var text = reader.readString();
        whiteboard.history.perform(
            TextInstanceAction(
                TextLayer(whiteboard)
                  ..fontSize = fontSize
                  ..text = text,
                position,
                true)
              ..userCreated = false,
            false);
        return true;

      case 3:
        var layer = getText();
        var fontSize = reader.readUInt8();
        var text = reader.readString();
        whiteboard.history.perform(
            TextUpdateAction(layer, null, text, null, fontSize)
              ..userCreated = false,
            false);
        return true;

      case 4:
        whiteboard.history.perform(
            TextMoveAction(getText(), null, reader.readPoint())
              ..userCreated = false,
            false);
        return true;

      case 5:
        whiteboard.history.perform(
            TextInstanceAction(getText(), null, false)..userCreated = false,
            false);
        return true;
    }

    return false;
  }
}

Future<Uint8List> blobToBytes(Blob blob) async {
  var reader = FileReader();
  reader.readAsArrayBuffer(blob);
  await reader.onLoadEnd.first;
  return reader.result;
}

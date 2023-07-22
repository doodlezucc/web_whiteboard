import 'dart:async';
import 'dart:html';

import 'dart:typed_data';

import '../binary.dart';
import '../layers/drawing_layer.dart';
import '../layers/drawn_stroke.dart';
import '../layers/text_layer.dart';
import '../stroke.dart';
import '../whiteboard.dart';
import 'binary_event.dart';
import 'socket_base.dart';

class WhiteboardSocket extends SocketBase {
  Whiteboard whiteboard;
  final _controller = StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get sendStream => _controller.stream;

  /// `prefix` may define a string prepended to incoming and outgoing events.
  /// Keep it unique so whiteboard messages don't mix up with other traffic
  /// on your websocket.
  WhiteboardSocket({required this.whiteboard, String prefix = ''})
      : super(prefix);

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

    final reader = BinaryReader(bytes.sublist(prefixBytes.length).buffer);

    DrawingLayer getLayer() {
      return whiteboard.layers[reader.readUInt8()];
    }

    TextLayer getText() {
      return whiteboard.texts[reader.readUInt8()];
    }

    switch (reader.readUInt8()) {
      case 0:
        var layer = getLayer();
        var strokes = <Stroke>[];
        var count = reader.readUInt8();
        for (var i = 0; i < count; i++) {
          strokes.add(Stroke()..loadFromBytes(reader));
        }
        whiteboard.history.perform(
            StrokeAction(layer, true, strokes, const [])..userCreated = false,
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
            StrokeAction(layer, false, toRemove, const [])..userCreated = false,
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
            TextUpdateAction(layer, text, text, fontSize, fontSize)
              ..userCreated = false,
            false);
        return true;

      case 4:
        final textLayer = getText();
        final position = reader.readPoint();

        whiteboard.history.perform(
            TextMoveAction(textLayer, position, position)..userCreated = false,
            false);
        return true;

      case 5:
        final textLayer = getText();
        whiteboard.history.perform(
            TextInstanceAction(textLayer, textLayer.position, false)
              ..userCreated = false,
            false);
        return true;

      case 6:
        whiteboard.pin.loadFromBytes(reader);
        return true;

      case 7:
        whiteboard.clear(sendEvent: false, deleteLayers: reader.readBool());
        return true;

      case 8:
        var strokeCount = reader.readUInt8();
        var strokes = <DrawnStroke>[];
        for (var i = 0; i < strokeCount; i++) {
          strokes.add(DrawnStroke(getLayer(), Stroke()..loadFromBytes(reader)));
        }
        whiteboard.history.perform(
            StrokeAcrossAction(true, strokes, const {})..userCreated = false,
            false);
        return true;

      case 9:
        var strokeCount = reader.readUInt8();
        var toRemove = <DrawnStroke>[];
        var affectedLayers = <DrawingLayer>{};
        for (var i = 0; i < strokeCount; i++) {
          var layer = getLayer();
          affectedLayers.add(layer);

          var index = reader.readUInt8();
          toRemove.add(DrawnStroke(layer, layer.strokes[index]));
        }
        // Unregister active layer actions
        whiteboard.history.discardActionsWhere(
            (a) => a is StrokeAction && affectedLayers.contains(a.layer));

        whiteboard.history.perform(
            StrokeAcrossAction(false, toRemove, const {})..userCreated = false,
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
  return reader.result as Uint8List;
}

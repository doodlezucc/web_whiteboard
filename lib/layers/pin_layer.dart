import 'dart:async';
import 'dart:math';
import 'dart:svg' as svg;

import 'package:web_whiteboard/communication/binary_event.dart';
import 'package:web_whiteboard/history.dart';
import 'package:web_whiteboard/layers/layer.dart';
import 'package:web_whiteboard/layers/pin_data.dart';
import 'package:web_whiteboard/util.dart';
import 'package:web_whiteboard/whiteboard.dart';

class PinLayer extends Layer with PinData {
  svg.CircleElement get pinElement => layerEl;

  @override
  set visible(bool visible) {
    super.visible = visible;
    pinElement.classes.toggle('visible', visible);
  }

  @override
  set position(Point position) {
    var p = forceIntPoint(position);
    super.position = p;
    pinElement
      ..cx.baseVal.value = p.x
      ..cy.baseVal.value = p.y;
  }

  PinLayer(Whiteboard canvas) : super(canvas, svg.CircleElement()) {
    pinElement
      ..id = 'whiteboardPin'
      ..r.baseVal.value = 25;
  }

  @override
  Future<Action> onMouseDown(Point first, Stream<Point> stream) async {
    var completer = Completer();
    visible = true;

    position = first;

    stream.listen((p) {
      position = p;
    }, onDone: () => completer.complete());

    await completer.future;

    if (visible) {
      sendUpdateEvent();
    }

    return null;
  }

  void hide() {
    visible = false;
    sendUpdateEvent();
  }

  void sendUpdateEvent() {
    canvas.socket.send(BinaryEvent(6)
      ..writeBool(visible)
      ..writePoint(position));
  }
}

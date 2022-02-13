import 'dart:html';
import 'dart:js';

import 'package:web_whiteboard/binary.dart';
import 'package:web_whiteboard/whiteboard.dart';

void main() {
  var src =
      'https://i.pinimg.com/originals/cc/2a/28/cc2a2884782eca399299b3243ce66231.jpg';

  var canvas = Whiteboard(querySelector('#canvas'))
    ..changeBackground(src)
    ..addDrawingLayer()
    ..addDrawingLayer()
    ..addDrawingLayer()
    ..addDrawingLayer()
    ..eraseAcrossLayers = true;
  var canvas2 = Whiteboard(querySelector('#canvasClone'))
    ..captureInput = false
    ..changeBackground(src);

  // You don't need a <canvas> element for whiteboards. In this example,
  // htmlCanvas is only used to test the "Whiteboard.drawToCanvas" function.
  CanvasElement htmlCanvas = querySelector('canvas');

  window.onKeyDown.listen((ev) {
    if (ev.target is TextAreaElement) return;

    if (!ev.ctrlKey) {
      if (ev.key == 'q') {
        ev.preventDefault();
        canvas.mode = canvas.mode == Whiteboard.modeDraw
            ? Whiteboard.modeText
            : Whiteboard.modeDraw;
        print('Mode: ${canvas.mode}');
      } else if (ev.key == 'e') {
        ev.preventDefault();
        canvas.eraser = !canvas.eraser;
        print('Eraser: ${canvas.eraser}');
      } else if (ev.key == 'ArrowUp') {
        ev.preventDefault();
        if (canvas.layerIndex < canvas.layers.length - 1) {
          canvas.layerIndex++;
          print('Layer: ${canvas.layerIndex}');
        }
      } else if (ev.key == 'ArrowDown') {
        ev.preventDefault();
        if (canvas.layerIndex > 0) {
          canvas.layerIndex--;
          print('Layer: ${canvas.layerIndex}');
        }
      }
    } else {
      if (ev.key == 's') {
        ev.preventDefault();
        print(canvas.encode());
      } else if (ev.key == 'r') {
        ev.preventDefault();
        var data = context.callMethod(
          'prompt',
          ['Enter encoded canvas data'],
        );

        if (data != null) {
          print(data);
          canvas.decode(data);
        }
      } else if (ev.key == 'Delete' || ev.key == 'Backspace') {
        ev.preventDefault();
        canvas.clear();
      }
    }
  });

  var reader = BinaryReader(canvas.toBytes().buffer);
  canvas2.loadFromBytes(reader);
  canvas.socket.sendStream.listen((event) {
    canvas.drawToCanvas(htmlCanvas);
    print(event);
    canvas2.socket.handleEventBytes(event);
  });
}

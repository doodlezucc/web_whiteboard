import 'dart:html';
import 'dart:js';

import 'package:web_whiteboard/whiteboard.dart';

void main() {
  var src =
      'https://i.pinimg.com/originals/cc/2a/28/cc2a2884782eca399299b3243ce66231.jpg';

  var canvas = Whiteboard(querySelector('#canvas'))..changeBackground(src);
  var canvas2 = Whiteboard(querySelector('#canvasClone'))
    ..useShortcuts = false
    ..changeBackground(src);

  window.onKeyDown.listen((ev) {
    if (ev.target is TextAreaElement) return;

    if (!ev.ctrlKey) {
      if (ev.key == 'q') {
        ev.preventDefault();
        canvas.mode = canvas.mode == Whiteboard.modeDraw
            ? Whiteboard.modeText
            : Whiteboard.modeDraw;
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

  canvas.socket.sendStream.listen((event) {
    canvas2.socket.handleEvent(event);
  });
}

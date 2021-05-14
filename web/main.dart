import 'dart:html';
import 'dart:js';

import 'package:web_whiteboard/whiteboard.dart';

void main() {
  var canvas = Whiteboard(querySelector('#canvas'));

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
}

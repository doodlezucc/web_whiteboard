import 'dart:html';

import 'package:web_whiteboard/whiteboard.dart';

import 'dart/client_websocket.dart';

final clientSocket = ClientWebsocket();

const src =
    'https://i.pinimg.com/originals/cc/2a/28/cc2a2884782eca399299b3243ce66231.jpg';
final whiteboard = Whiteboard(querySelector('#canvas'))
  ..changeBackground(src)
  ..socket.sendStream.listen((data) => clientSocket.send(data));

void main() {
  // Establish connection to localhost:7070 where the server is running
  clientSocket.connect();

  window.onKeyDown.listen((ev) {
    if (ev.target is TextAreaElement) return;

    if (!ev.ctrlKey) {
      if (ev.key == 'q') {
        ev.preventDefault();
        whiteboard.mode = whiteboard.mode == Whiteboard.modeDraw
            ? Whiteboard.modeText
            : Whiteboard.modeDraw;
        print(whiteboard.mode + ' mode');
      }
    }
  });
}

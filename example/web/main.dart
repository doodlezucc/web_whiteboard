import 'dart:html';
import 'dart:math';

import 'package:web_whiteboard/whiteboard.dart';

import 'dart/client_websocket.dart';

final clientSocket = ClientWebsocket();

const src =
    'https://i.pinimg.com/originals/cc/2a/28/cc2a2884782eca399299b3243ce66231.jpg';
final whiteboard = Whiteboard(querySelector('#canvas'), webSocketPrefix: '%wb')
  ..changeBackground(src)
  ..socket.sendStream.listen((data) => clientSocket.send(data));

void main() {
  // Establish connection to localhost:7070 where the server is running
  clientSocket.connect();

  _initWhiteboardShortcuts();
  _initLayerInput();
  _initColorInput();
}

void _initWhiteboardShortcuts() {
  window.onKeyDown.listen((ev) {
    if (_handleKeyEvent(ev)) {
      ev.preventDefault();
    }
  });
}

void _initLayerInput() {
  InputElement input = querySelector('input[type=range]');
  input.onInput.listen((_) {
    whiteboard.layerIndex = min(max(input.valueAsNumber, 0), 10);
  });
}

void _initColorInput() {
  InputElement input = querySelector('input[type=color]');
  input.onInput.listen((_) {
    whiteboard.activeColor = input.value;
  });
}

bool _handleKeyEvent(KeyboardEvent ev) {
  if (ev.target is TextAreaElement) return false;

  if (ev.shiftKey && ev.key == 'Delete') {
    whiteboard.clear();
    print('cleared whiteboard');
    return true;
  }

  if (!ev.ctrlKey) {
    switch (ev.keyCode) {
      case 68:
        // D key
        whiteboard.mode = Whiteboard.modeDraw;
        print('draw mode');
        return true;

      case 69:
        // E key
        whiteboard.mode = Whiteboard.modeDraw;
        whiteboard.eraser = true;
        whiteboard.eraseAcrossLayers = ev.shiftKey;
        print('erase mode (across layers: ${ev.shiftKey})');
        return true;

      case 84:
        // T key
        whiteboard.mode = Whiteboard.modeText;
        print('text mode');
        return true;

      case 85:
        // T key
        whiteboard.mode = Whiteboard.modePin;
        print('text mode');
        return true;
    }
  }
  return false;
}

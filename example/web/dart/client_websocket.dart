import 'dart:async';
import 'dart:html';

import '../main.dart';

class ClientWebsocket {
  WebSocket? _webSocket;

  void connect() async {
    _webSocket = WebSocket('ws://localhost:7070/ws');

    // Process whiteboard data sent by the server on connection
    await whiteboard.loadFromBlob(await messageStream.first);

    // Handle whiteboard events
    messageStream.listen((data) async {
      if (!await whiteboard.socket.handleEvent(data)) {
        print(data);
      }
    });
  }

  Stream get messageStream {
    if (_webSocket == null) {
      throw 'Websocket not connected';
    }

    return _webSocket!.onMessage.map((event) => event.data);
  }

  Future<void> send(data) async {
    _webSocket?.send(data);
  }
}

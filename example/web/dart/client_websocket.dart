import 'dart:async';
import 'dart:html';

import '../main.dart';

class ClientWebsocket {
  WebSocket _webSocket;
  final _waitForOpen = Completer();

  void connect() async {
    _webSocket = WebSocket('ws://localhost:7070/ws')
      ..onOpen.listen((e) => _waitForOpen.complete())
      ..onClose.listen((e) => print('CLOSE'))
      ..onError.listen((e) => print(e));

    await whiteboard.loadFromBlob(await messageStream.first);

    messageStream.listen((data) {
      whiteboard.socket.handleEvent(data);
    });
  }

  Stream get messageStream => _webSocket.onMessage.map((event) => event.data);

  Future<void> send(data) async {
    await _waitForOpen.future;
    print('Sending');
    _webSocket.send(data);
  }
}

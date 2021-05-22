import 'package:web_socket_channel/web_socket_channel.dart';

import 'server.dart';

final connections = <Connection>[];

void onConnect(WebSocketChannel ws) {
  print('New connection!');
  connections.add(Connection(ws));
}

class Connection {
  final WebSocketChannel ws;
  final Stream stream;

  Connection(this.ws) : stream = ws.stream.asBroadcastStream() {
    stream.listen(
      (data) {
        // If data is a whiteboard event, forward it to other connections
        if (whiteboardSocket.handleEvent(data)) {
          for (var connection in connections) {
            if (connection != this) {
              connection.send(data);
            }
          }
        } else {
          print('Unhandled data:');
          print(data);
        }
      },
      onDone: () {
        print('Lost connection (${ws.closeCode})');
        connections.remove(this);
      },
    );

    // Send the current state of the whiteboard
    send(whiteboardSocket.whiteboard.toBytes());
  }

  Future<void> send(data) async => ws.sink.add(data);
}

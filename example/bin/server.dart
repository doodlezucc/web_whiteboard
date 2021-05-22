import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart' as ws;
import 'package:web_whiteboard/communication/data_socket.dart';
import 'package:web_whiteboard/layers/drawing_data.dart';
import 'package:web_whiteboard/whiteboard_data.dart';

import 'websockets.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = 'localhost';

final whiteboardSocket = WhiteboardDataSocket(
  WhiteboardData()..layers.add(DrawingData()),
  prefix: '%wb',
);

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '7070';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  // Response _cors(Response response) => response.change(headers: {
  //       'Access-Control-Allow-Origin': '*',
  //       'Access-Control-Allow-Methods': 'GET, POST',
  //       'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
  //     });

  // var _fixCORS = createMiddleware(responseHandler: _cors);

  var handler = const Pipeline()
      // .addMiddleware(_fixCORS)
      .addMiddleware(logRequests())
      .addHandler(_echoRequest);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

String getMimeType(File f) {
  switch (path.extension(f.path)) {
    case '.html':
      return 'text/html';
    case '.css':
      return 'text/css';
    case '.js':
      return 'text/javascript';
  }
  return 'text/plain';
}

Future<Response> _echoRequest(Request request) async {
  var path = request.url.path;

  if (path == 'ws') {
    return await ws.webSocketHandler(onConnect)(request);
  } else if (path.isEmpty || path == 'home') {
    path = 'index.html';
  }

  var file = File('web/' + path);

  if (await file.exists()) {
    var type = getMimeType(file);
    return Response(
      200,
      body: file.openRead(),
      headers: {'Content-Type': type},
    );
  }

  return Response.notFound('Request for "${request.url}"');
}

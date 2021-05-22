import 'dart:convert';

abstract class SocketBase {
  String prefix;
  List<int> get prefixBytes => utf8.encode(prefix);

  SocketBase(this.prefix);

  /// Returns true if the socket prefix is found at the start of `bytes`.
  bool matchPrefix(List<int> bytes) {
    var preBytes = prefixBytes;

    for (var i = 0; i < preBytes.length; i++) {
      if (bytes[i] != preBytes[i]) return false;
    }

    return true;
  }
}

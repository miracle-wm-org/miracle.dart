import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A stand-in for miracle's IPC socket.
///
/// It speaks the same framing as the real compositor, replies to requests
/// with whatever [onRequest] returns, and can push events at will.
class FakeMiracle {
  FakeMiracle._(this._server, this.socketPath, this._directory);

  static const String _magic = 'i3-ipc';
  static const int _headerSize = 14;

  final ServerSocket _server;
  final Directory _directory;

  /// The path clients should connect to.
  final String socketPath;

  final List<Socket> _clients = [];
  final List<(int type, String payload)> requests = [];

  /// Called for every request; the returned payload is sent back with the
  /// same type, i3-style.
  String Function(int type, String payload)? onRequest;

  /// Completes once at least one client has connected.
  Future<void> get clientConnected => _clientConnected.future;
  final Completer<void> _clientConnected = Completer<void>();

  static Future<FakeMiracle> start() async {
    final directory = await Directory.systemTemp.createTemp('fake_miracle');
    final path = '${directory.path}/miracle.sock';
    final server = await ServerSocket.bind(
      InternetAddress(path, type: InternetAddressType.unix),
      0,
    );
    final fake = FakeMiracle._(server, path, directory);
    server.listen(fake._onClient);
    return fake;
  }

  void _onClient(Socket socket) {
    _clients.add(socket);
    if (!_clientConnected.isCompleted) _clientConnected.complete();

    var buffer = Uint8List(0);
    socket.listen(onDone: () => _clients.remove(socket),
        onError: (Object _) => _clients.remove(socket), (data) {
      buffer = Uint8List.fromList([...buffer, ...data]);
      while (buffer.length >= _headerSize) {
        final view = ByteData.sublistView(buffer);
        final length = view.getUint32(6, Endian.host);
        final type = view.getUint32(10, Endian.host);
        if (buffer.length < _headerSize + length) break;
        final payload = utf8.decode(
          Uint8List.sublistView(buffer, _headerSize, _headerSize + length),
        );
        buffer = Uint8List.fromList(buffer.sublist(_headerSize + length));
        requests.add((type, payload));
        final reply = onRequest?.call(type, payload);
        if (reply != null) _send(socket, type, reply);
      }
    });
  }

  /// Pushes an event of [type] carrying [payload] to every client.
  void pushEvent(int type, Object? payload) {
    for (final client in List<Socket>.from(_clients)) {
      _send(client, type, jsonEncode(payload));
    }
  }

  /// Pushes several events of [type] to every client in a single write.
  void pushEvents(int type, List<Object?> payloads) {
    for (final client in List<Socket>.from(_clients)) {
      final message = <int>[];
      for (final payload in payloads) {
        message.addAll(_frame(type, jsonEncode(payload)));
      }
      client.add(message);
    }
  }

  /// Pushes one event of [type] as two writes, split after [splitAt] bytes.
  Future<void> pushEventInChunks(
    int type,
    Object? payload, {
    required int splitAt,
  }) async {
    for (final client in List<Socket>.from(_clients)) {
      final message = _frame(type, jsonEncode(payload));
      client.add(message.sublist(0, splitAt));
      await client.flush();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      client.add(message.sublist(splitAt));
    }
  }

  /// Pushes a raw, possibly malformed, message to every client.
  void pushRaw(int type, String payload) {
    for (final client in List<Socket>.from(_clients)) {
      _send(client, type, payload);
    }
  }

  /// Completes once [count] clients have been accepted.
  Future<void> waitForClients(int count) async {
    while (_clients.length < count) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  void _send(Socket socket, int type, String payload) {
    try {
      socket.add(_frame(type, payload));
    } on SocketException {
      // The client went away; nothing to do in a test double.
      _clients.remove(socket);
    }
  }

  Uint8List _frame(int type, String payload) {
    final bytes = utf8.encode(payload);
    final message = Uint8List(_headerSize + bytes.length);
    final view = ByteData.sublistView(message);
    message.setRange(0, 6, utf8.encode(_magic));
    view.setUint32(6, bytes.length, Endian.host);
    view.setUint32(10, type, Endian.host);
    message.setRange(_headerSize, message.length, bytes);
    return message;
  }

  Future<void> stop() async {
    for (final client in List<Socket>.from(_clients)) {
      client.destroy();
    }
    _clients.clear();
    await _server.close();
    if (_directory.existsSync()) {
      await _directory.delete(recursive: true);
    }
  }
}

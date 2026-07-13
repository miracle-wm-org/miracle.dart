import 'dart:io';

import 'package:miracle/miracle.dart';
import 'package:test/test.dart';

void main() {
  group('MiracleConnection.connect', () {
    late Directory tempDir;
    late String socketPath;
    late ServerSocket server;
    late MiracleConnection connection;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('miracle_ipc_test');
      socketPath = '${tempDir.path}/miracle.sock';
      server = await ServerSocket.bind(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      );
      connection = MiracleConnection();
    });

    tearDown(() async {
      connection.disconnect();
      await server.close();
      await tempDir.delete(recursive: true);
    });

    test('accepts an onSocketError callback', () async {
      await connection.connect(
        socketPath: socketPath,
        onSocketError: (error, stackTrace) {},
      );
    });

    test('connects without any callbacks', () async {
      await connection.connect(socketPath: socketPath);
    });

    test('throws when no socket path is available', () {
      expect(
        () => connection.connect(socketPath: ''),
        throwsA(isA<Exception>()),
      );
    });
  });
}

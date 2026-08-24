import 'dart:async';
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
      await connection.disconnect();
      await server.close();
      await tempDir.delete(recursive: true);
    });

    test('accepts an onSocketError callback', () async {
      await connection.connect(
        socketPath: socketPath,
        onSocketError: (error, stackTrace) {},
      );
      expect(connection.isConnected, isTrue);
    });

    test('connects without any callbacks', () async {
      await connection.connect(socketPath: socketPath);
      expect(connection.isConnected, isTrue);
    });

    test('throws when no socket path is available', () {
      expect(
        () => connection.connect(socketPath: ''),
        throwsA(isA<MiracleConnectionException>()),
      );
    });

    test('reconnects after being disconnected', () async {
      await connection.connect(socketPath: socketPath);
      await connection.disconnect();
      expect(connection.isConnected, isFalse);

      await connection.connect(socketPath: socketPath);
      expect(connection.isConnected, isTrue);
      // The event stream is usable again.
      expect(connection.listen((_) {}), isA<StreamSubscription<Event>>());
    });

    test('refuses to send anything while disconnected', () {
      expect(connection.getTree(), throwsA(isA<MiracleConnectionException>()));
    });
  });

  group('MiracleConnection.resolveSocketPath', () {
    test('prefers MIRACLESOCK', () {
      expect(
        MiracleConnection.resolveSocketPath({
          'MIRACLESOCK': '/run/miracle.sock',
          'SWAYSOCK': '/run/sway.sock',
          'I3SOCK': '/run/i3.sock',
        }),
        '/run/miracle.sock',
      );
    });

    test('falls back to SWAYSOCK and then I3SOCK', () {
      expect(
        MiracleConnection.resolveSocketPath({'SWAYSOCK': '/run/sway.sock'}),
        '/run/sway.sock',
      );
      expect(
        MiracleConnection.resolveSocketPath({'I3SOCK': '/run/i3.sock'}),
        '/run/i3.sock',
      );
    });

    test('ignores empty values and reports nothing when unset', () {
      expect(
        MiracleConnection.resolveSocketPath(
            {'MIRACLESOCK': '', 'SWAYSOCK': '/run/sway.sock'}),
        '/run/sway.sock',
      );
      expect(MiracleConnection.resolveSocketPath({}), isNull);
    });
  });

  group('IpcType', () {
    test('maps wire values back to types', () {
      expect(IpcType.fromValue(0), IpcType.ipcCommand);
      expect(IpcType.fromValue(200), IpcType.ipcGetDebugState);
      expect(IpcType.fromValue(201), IpcType.ipcPluginCommand);
      expect(IpcType.fromValue(0x80000016), IpcType.ipcEventConfigErrors);
      expect(IpcType.fromValue(0x80000017), IpcType.ipcEventPlugin);
      expect(IpcType.fromValue(0x80000099), isNull);
    });

    test('knows which types are events', () {
      expect(IpcType.ipcEventWorkspace.isEvent, isTrue);
      expect(IpcType.ipcGetTree.isEvent, isFalse);
    });
  });

  group('SubscriptionType', () {
    test('carries the wire name miracle expects', () {
      expect(SubscriptionType.configErrors.wireName, 'config_errors');
      expect(SubscriptionType.fromWireName('config_errors'),
          SubscriptionType.configErrors);
      expect(SubscriptionType.fromWireName('my-plugin'), isNull);
    });

    test('knows which names are reserved', () {
      expect(SubscriptionType.isReservedName('window'), isTrue);
      expect(SubscriptionType.isReservedName('my-plugin'), isFalse);
    });
  });
}

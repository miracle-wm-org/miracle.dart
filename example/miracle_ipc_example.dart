import 'dart:io';

import 'package:miracle/miracle.dart';

void main() async {
  // Establish the connection.
  final MiracleConnection connection = MiracleConnection();
  try {
    await connection.connect();
  } catch (e) {
    print('Unable to connect to the socket: $e');
    exit(1);
  }

  // Get the miracle version
  final VersionResult version = await connection.getVersion();
  print(version);

  // Get the current miracle tree
  final BaseNode tree = await connection.getTree();
  print(tree);

  // Get the available modes
  final BindingModesResult modes = await connection.getBindingModes();
  print(modes);

  // Get the current mode.
  final BindingStateResult bindingState = await connection.getBindingState();
  print(bindingState);

  // Send a tick.
  final TickResult tick = await connection.sendTick();
  print(tick);

  // Request a sync.
  final SyncResult sync = await connection.sync();
  print(sync);

  // Subscribe to workspace events
  final SubscribeResult subscribeResponse =
      await connection.subscribe([SubscriptionType.workspace]);
  if (!subscribeResponse.success) {
    print('Failed to subscribe: ${subscribeResponse.error}');
  }

  print('Listening for events (press Ctrl+C to exit)');
  await for (final event in connection) {
    print('Received event: $event');
  }

  // Keep the program running to receive events
  await Future.delayed(Duration(days: 1));
}

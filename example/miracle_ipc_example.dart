import 'dart:io';

import 'package:miracle/miracle.dart';

void main() async {
  // Establish the connection. The socket path comes from MIRACLESOCK, falling
  // back to SWAYSOCK and then I3SOCK.
  final MiracleConnection connection = MiracleConnection();
  try {
    await connection.connect(
      onSocketError: (error, stackTrace) => print('Socket error: $error'),
      onSocketDone: () => print('Socket closed'),
    );
  } catch (e) {
    print('Unable to connect to the socket: $e');
    exit(1);
  }

  // Get the miracle version.
  final VersionResult version = await connection.getVersion();
  print(version);

  // Get the current miracle tree, and walk it.
  final BaseNode tree = await connection.getTree();
  print(tree);
  for (final window in tree.windows) {
    print('window ${window.id}: ${window.appId} at ${window.rect}');
  }

  // List the outputs and the workspaces on them.
  for (final OutputResult output in await connection.getOutputs()) {
    print('${output.name}: ${output.currentMode} -> '
        'workspace ${output.currentWorkspace}');
  }

  // Get the available modes and the current one.
  print(await connection.getBindingModes());
  print(await connection.getBindingState());

  // Get the marks that are currently set.
  print(await connection.getMarks());

  // Send commands without hand-writing the command string.
  await connection.runAll([
    MiracleCommand.mark('swapee'),
    MiracleCommand.focusDirection(Direction.left),
    MiracleCommand.swapWithMark('swapee'),
  ]);

  // ...or throw if miracle rejects one.
  try {
    await connection.runOrThrow(MiracleCommand.workspace('2'));
  } on MiracleCommandException catch (e) {
    print(e);
  }

  // Ask a plugin to do something, and read its answer.
  final PluginCommandResult plugin = await connection.pluginCommand(
    'my-plugin',
    {'action': 'toggle'},
  );
  print(plugin);

  // Take a debugging snapshot (miracle v0.10.0 and newer).
  final DebugState debugState = await connection.getDebugState();
  print('${debugState.windows.length} windows, '
      'cursor at ${debugState.cursor}, '
      'over ${debugState.windowUnderCursorInfo?.appId ?? 'nothing'}');

  // Subscribe to the events we care about, including a plugin namespace.
  final SubscribeResult subscribeResponse = await connection.subscribe(
    [
      SubscriptionType.workspace,
      SubscriptionType.window,
      SubscriptionType.configErrors,
    ],
    pluginNamespaces: ['my-plugin'],
  );
  if (!subscribeResponse.success) {
    print('Failed to subscribe: ${subscribeResponse.error}');
  }

  // Listen to one kind of event at a time...
  connection.windowEvents.listen((event) {
    print('window ${event.container.appId} ${event.change.name}');
  });
  connection.configErrorEvents.listen((event) {
    for (final error in event.errors) {
      print('config: $error');
    }
  });
  connection.pluginEventsFor('my-plugin').listen((event) {
    print('my-plugin published ${event.payload}');
  });

  // ...or to everything at once.
  print('Listening for events (press Ctrl+C to exit)');
  await for (final event in connection) {
    switch (event) {
      case WorkspaceEvent(:final change, :final current):
        print('workspace ${current?.name} ${change.name}');
      case ShutdownEvent(:final change):
        print('miracle is going away: ${change.name}');
        await connection.disconnect();
        return;
      default:
        print('Received event: $event');
    }
  }
}

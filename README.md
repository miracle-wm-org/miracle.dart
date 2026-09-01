# miracle-ipc.dart
[![CI](https://github.com/miracle-wm-org/miracle.dart/actions/workflows/ci.yml/badge.svg)](https://github.com/miracle-wm-org/miracle.dart/actions/workflows/ci.yml)

A strongly-typed Dart API for interacting with the [miracle](https://miracle-wm.org)
tiling window manager from Dart and Flutter.

It covers all of [miracle's IPC protocol](https://wiki.miracle-wm.org/develop/ipc/):
every message, every event and every command. See
[`doc/ipc_coverage.md`](doc/ipc_coverage.md) for the coverage map.

## Installation

```yaml
dependencies:
  miracle: ^2.1.0
```

## Connecting

The socket path is read from `MIRACLESOCK`, falling back to `SWAYSOCK` and
then `I3SOCK`.

```dart
import 'package:miracle/miracle.dart';

final connection = MiracleConnection();
await connection.connect();
```

## Asking miracle about itself

```dart
final version = await connection.getVersion();
final tree = await connection.getTree();
final outputs = await connection.getOutputs();
final workspaces = await connection.getWorkspaces();
final marks = await connection.getMarks();
final modes = await connection.getBindingModes();
final state = await connection.getBindingState();
final debugState = await connection.getDebugState();
```

Any node in the tree can be walked:

```dart
for (final window in tree.windows) {
  print('${window.appId}: ${window.rect}');
}
print(tree.findById(someId));
print(tree.focusedNode);
```

## Running commands

Commands are built rather than spelled out, so a typo is a compile error
instead of a `parse_error` at runtime:

```dart
await connection.run(MiracleCommand.focusDirection(Direction.left));

await connection.runAll([
  MiracleCommand.mark('swapee'),
  MiracleCommand.focusDirection(Direction.left),
  MiracleCommand.swapWithMark('swapee'),
]);

// [app_id="firefox"] focus
await connection.run(
  MiracleCommand.focusMatching(const Criteria(appId: 'firefox')),
);

// Throws MiracleCommandException if miracle rejects the command.
await connection.runOrThrow(MiracleCommand.workspace('2'));
```

Anything the builders do not cover still goes through verbatim:

```dart
await connection.command('fullscreen toggle');
```

## Listening to events

Subscribe first, then listen — to one kind of event, or to all of them:

```dart
await connection.subscribe([
  SubscriptionType.workspace,
  SubscriptionType.window,
]);

connection.windowEvents.listen((event) {
  print('${event.container.appId} ${event.change.name}');
});

await for (final event in connection) {
  switch (event) {
    case WorkspaceEvent(:final change, :final current):
      print('workspace ${current?.name} ${change.name}');
    case ShutdownEvent():
      return;
    default:
      break;
  }
}
```

Plugin events are subscribed to per namespace:

```dart
await connection.subscribeToPlugin('my-plugin');
connection.pluginEventsFor('my-plugin').listen(print);

final result = await connection.pluginCommand('my-plugin', {'action': 'toggle'});
```

## Urgency

A window that asks to be raised while it is off screen is flagged as urgent
rather than being allowed to steal focus, and the flag clears once it is
focused. Urgency propagates up the tree, so a workspace or an output is urgent
whenever a window beneath it is:

```dart
for (final window in tree.urgentWindows) {
  print('${window.appId} wants attention');
}

final urgentWorkspaces = tree.workspaces.where((w) => w.isUrgent);
```

miracle announces a change on both the `window` and the `workspace` event, so
a bar can watch whichever it already draws:

```dart
connection.windowEvents
    .where((event) => event.change == WindowChange.urgent)
    .listen((event) {
  print('${event.container.appId} is urgent: ${event.container.urgent}');
});

connection.workspaceEvents
    .where((event) => event.change == WorkspaceChange.urgent)
    .listen((event) {
  print('workspace ${event.current?.name} is urgent: ${event.current?.urgent}');
});
```

## Example

See [`example/miracle_ipc_example.dart`](example/miracle_ipc_example.dart) for
a tour of the whole API.

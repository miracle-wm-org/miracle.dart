/// A strongly-typed Dart API for miracle-wm's IPC mechanism.
///
/// The entry point is [MiracleConnection], which speaks the i3-compatible
/// protocol documented at <https://wiki.miracle-wm.org/develop/ipc/>:
///
/// ```dart
/// final connection = MiracleConnection();
/// await connection.connect();
///
/// final tree = await connection.getTree();
/// for (final window in tree.windows) {
///   print('${window.appId}: ${window.rect}');
/// }
///
/// await connection.subscribe([SubscriptionType.window]);
/// connection.windowEvents.listen((event) {
///   print('${event.container.appId} ${event.change.name}');
/// });
/// ```
library;

export 'src/commands.dart';
export 'src/debug_state.dart';
export 'src/events.dart';
export 'src/geometry.dart';
export 'src/ipc_type.dart';
export 'src/miracle_ipc.dart';
export 'src/nodes.dart';
export 'src/replies.dart';

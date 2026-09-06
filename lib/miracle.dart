/// A strongly-typed Dart API for miracle-wm.
///
/// The package covers two things. [MiracleConnection] speaks the
/// miracle-compatible IPC protocol documented at
/// <https://wiki.miracle-wm.org/develop/ipc/>, for talking to a running
/// compositor:
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
///
/// [MiracleConfig] reads and writes miracle's configuration file, through the
/// `libmiracle-wm-c` library that ships with miracle-wm:
///
/// ```dart
/// final config = MiracleConfig.loadDefault();
/// try {
///   config.innerGapsX = 10;
///   config.startupApps.add(const StartupApp(command: 'nm-applet'));
///   config.save();
/// } finally {
///   config.dispose();
/// }
/// ```
library;

export 'src/config/miracle_config.dart';
export 'src/ipc/commands.dart';
export 'src/ipc/debug_state.dart';
export 'src/ipc/events.dart';
export 'src/ipc/geometry.dart';
export 'src/ipc/ipc_type.dart';
export 'src/ipc/miracle_ipc.dart';
export 'src/ipc/nodes.dart';
export 'src/ipc/replies.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'commands.dart';
import 'debug_state.dart';
import 'events.dart';
import 'ipc_type.dart';
import 'json.dart';
import 'nodes.dart';
import 'replies.dart';

/// Thrown when the connection to miracle cannot be established or used.
class MiracleConnectionException implements Exception {
  /// A human-readable description of what went wrong.
  final String message;

  MiracleConnectionException(this.message);

  @override
  String toString() => 'MiracleConnectionException: $message';
}

/// The environment variables that carry the path to miracle's IPC socket.
///
/// miracle sets all three, the latter two for compatibility with sway and i3
/// respectively, and they are searched in this order.
const List<String> kSocketPathEnvironmentVariables = [
  'MIRACLESOCK',
  'SWAYSOCK',
  'I3SOCK',
];

/// A connection to miracle's IPC.
///
/// Callers may use the methods defined on the class to send requests to
/// miracle.
///
/// Alternatively, callers may listen to events on miracle by first calling
/// [MiracleConnection.subscribe] and then listening on the stream, either as
/// a whole or one event type at a time.
///
/// Example:
/// ```dart
/// // Create a new connection
/// final connection = MiracleConnection();
///
/// // Connect to miracle
/// await connection.connect();
///
/// // Send a command to switch to workspace 2
/// await connection.run(MiracleCommand.workspace('2'));
///
/// // Subscribe to workspace and window events
/// await connection.subscribe([
///   SubscriptionType.workspace,
///   SubscriptionType.window,
/// ]);
///
/// // Listen to the events you care about
/// connection.windowEvents.listen((event) {
///   print('${event.container.appId} ${event.change.name}');
/// });
///
/// // ...or to all of them at once
/// await for (final event in connection) {
///   print('Received event: $event');
/// }
/// ```
class MiracleConnection extends Stream<Event> {
  static const String _ipcMagic = 'i3-ipc';
  static const int _headerSize =
      14; // 6 bytes magic + 4 bytes length + 4 bytes type

  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSubscription;
  Uint8List _buffer = Uint8List(0);
  final Map<IpcType, Queue<Completer<String>>> _pendingResponses = {};
  StreamController<Event> _eventController =
      StreamController<Event>.broadcast();
  Duration? _requestTimeout;
  void Function(int type, String payload)? _onUnknownMessage;
  bool _reportedSocketError = false;

  /// Whether this connection is currently attached to a socket.
  bool get isConnected => _socket != null;

  /// The socket path miracle advertises, or `null` when it is not set.
  ///
  /// [kSocketPathEnvironmentVariables] are searched in order.
  static String? resolveSocketPath([Map<String, String>? environment]) {
    final env = environment ?? Platform.environment;
    for (final variable in kSocketPathEnvironmentVariables) {
      final path = env[variable];
      if (path != null && path.isNotEmpty) return path;
    }
    return null;
  }

  /// Connect to miracle's IPC socket.
  ///
  /// [socketPath] is the path of the socket to connect to. If it is omitted,
  /// the path is read from the `MIRACLESOCK` environment variable, falling
  /// back to `SWAYSOCK` and then `I3SOCK`.
  ///
  /// [onSocketError] will be called with the error and its stack trace when
  /// there is an error on the connection.
  /// [onSocketDone] will be called when the connection is closed.
  /// [onUnknownMessage] will be called with the raw type and payload of any
  /// message this package does not recognize at all.
  ///
  /// [requestTimeout], when given, bounds how long any single request waits
  /// for its reply before completing with a [TimeoutException].
  ///
  /// Returns a future. Once the future resolves, the connection is
  /// established.
  ///
  /// This will throw a [MiracleConnectionException] if no socket path can be
  /// found, or a [SocketException] if the socket cannot be connected to.
  Future<void> connect({
    String? socketPath,
    void Function(Object error, StackTrace stackTrace)? onSocketError,
    void Function()? onSocketDone,
    void Function(int type, String payload)? onUnknownMessage,
    Duration? requestTimeout,
  }) async {
    final path = socketPath ?? resolveSocketPath();
    if (path == null || path.isEmpty) {
      throw MiracleConnectionException(
        'No miracle socket found. Set one of '
        '${kSocketPathEnvironmentVariables.join(', ')}, or pass socketPath.',
      );
    }

    _requestTimeout = requestTimeout;
    _onUnknownMessage = onUnknownMessage;
    _reportedSocketError = false;
    if (_eventController.isClosed) {
      _eventController = StreamController<Event>.broadcast();
    }

    _socket = await Socket.connect(
      InternetAddress(path, type: InternetAddressType.unix),
      0,
    );
    _startListening(onSocketError, onSocketDone);
  }

  /// Disconnect from miracle's IPC socket.
  ///
  /// Any request that is still in flight completes with a
  /// [MiracleConnectionException]. The connection may be reused by calling
  /// [connect] again, which starts a fresh event stream.
  Future<void> disconnect() async {
    final subscription = _socketSubscription;
    final socket = _socket;
    _socketSubscription = null;
    _socket = null;
    _buffer = Uint8List(0);

    _failPendingResponses(
      MiracleConnectionException('The connection was closed'),
    );

    await subscription?.cancel();
    socket?.destroy();
    await _eventController.close();
  }

  @override
  StreamSubscription<Event> listen(
    void Function(Event event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _eventController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Every [WorkspaceEvent] pushed by miracle.
  ///
  /// Subscribe with [SubscriptionType.workspace] first.
  Stream<WorkspaceEvent> get workspaceEvents => whereType<WorkspaceEvent>();

  /// Every [WindowEvent] pushed by miracle.
  ///
  /// Subscribe with [SubscriptionType.window] first.
  Stream<WindowEvent> get windowEvents => whereType<WindowEvent>();

  /// Every [OutputEvent] pushed by miracle.
  ///
  /// Subscribe with [SubscriptionType.output] first.
  Stream<OutputEvent> get outputEvents => whereType<OutputEvent>();

  /// Every [ModeEvent] pushed by miracle.
  ///
  /// Subscribe with [SubscriptionType.mode] first.
  Stream<ModeEvent> get modeEvents => whereType<ModeEvent>();

  /// Every [BindingEvent] pushed by miracle.
  ///
  /// Subscribe with [SubscriptionType.binding] first.
  Stream<BindingEvent> get bindingEvents => whereType<BindingEvent>();

  /// Every [ShutdownEvent] pushed by miracle.
  ///
  /// Subscribe with [SubscriptionType.shutdown] first.
  Stream<ShutdownEvent> get shutdownEvents => whereType<ShutdownEvent>();

  /// Every [TickEvent] pushed by miracle.
  ///
  /// Subscribe with [SubscriptionType.tick] first.
  Stream<TickEvent> get tickEvents => whereType<TickEvent>();

  /// Every [ConfigErrorsEvent] pushed by miracle.
  ///
  /// Subscribe with [SubscriptionType.configErrors] first.
  Stream<ConfigErrorsEvent> get configErrorEvents =>
      whereType<ConfigErrorsEvent>();

  /// Every [PluginEvent] pushed by miracle, across all namespaces.
  ///
  /// Subscribe with [subscribeToPlugin] first.
  Stream<PluginEvent> get pluginEvents => whereType<PluginEvent>();

  /// Every [PluginEvent] published on the [namespace] plugin namespace.
  ///
  /// Subscribe with [subscribeToPlugin] first.
  Stream<PluginEvent> pluginEventsFor(String namespace) =>
      pluginEvents.where((event) => event.plugin == namespace);

  /// Every event of type [T] pushed by miracle.
  Stream<T> whereType<T extends Event>() =>
      _eventController.stream.where((event) => event is T).cast<T>();

  /// Starts listening for incoming messages from the socket
  void _startListening(
      void Function(Object error, StackTrace stackTrace)? onSocketError,
      void Function()? onSocketDone) {
    final socket = _socket;
    if (socket == null) {
      throw MiracleConnectionException('Not connected');
    }

    void reportError(Object error, StackTrace stackTrace) {
      _failPendingResponses(error, stackTrace);
      if (_reportedSocketError) return;
      _reportedSocketError = true;
      onSocketError?.call(error, stackTrace);
    }

    _socketSubscription = socket.listen(
      _onData,
      onError: reportError,
      onDone: () {
        _failPendingResponses(
          MiracleConnectionException('The connection was closed by miracle'),
        );
        onSocketDone?.call();
      },
      cancelOnError: false,
    );

    // A write that fails after the peer went away surfaces here rather than on
    // the subscription, and would otherwise be an unhandled async error.
    socket.done.then<void>((_) {}, onError: reportError);
  }

  /// Handles incoming data from the socket
  void _onData(List<int> data) {
    final combined = Uint8List(_buffer.length + data.length)
      ..setRange(0, _buffer.length, _buffer)
      ..setRange(_buffer.length, _buffer.length + data.length, data);

    var offset = 0;
    while (combined.length - offset >= _headerSize) {
      final view = ByteData.sublistView(combined, offset);

      // Parse header
      final magic = utf8.decode(
        Uint8List.sublistView(combined, offset, offset + 6),
        allowMalformed: true,
      );
      if (magic != _ipcMagic) {
        _eventController.addError(
          MiracleConnectionException('Invalid magic string: $magic'),
        );
        offset = combined.length;
        break;
      }

      // Read payload length and type (32-bit unsigned, native byte order)
      final payloadLength = view.getUint32(6, Endian.host);
      final payloadTypeValue = view.getUint32(10, Endian.host);

      // Check if we have the complete message
      final totalMessageSize = _headerSize + payloadLength;
      if (combined.length - offset < totalMessageSize) {
        // Not enough data yet, wait for more
        break;
      }

      final payload = utf8.decode(
        Uint8List.sublistView(
          combined,
          offset + _headerSize,
          offset + totalMessageSize,
        ),
      );
      offset += totalMessageSize;

      _handleMessage(IpcType.fromValue(payloadTypeValue), payloadTypeValue,
          payload);
    }

    _buffer = offset == 0
        ? combined
        : Uint8List.fromList(combined.sublist(offset));
  }

  /// Handles a complete parsed message
  void _handleMessage(
    IpcType? payloadType,
    int payloadTypeValue,
    String payload,
  ) {
    // Check if this is an event (high bit set)
    final isEvent = (payloadTypeValue & 0x80000000) != 0;

    if (isEvent) {
      if (payloadType == null) {
        _onUnknownMessage?.call(payloadTypeValue, payload);
        return;
      }
      _handleEvent(payloadType, payload);
      return;
    }

    // Complete the oldest request waiting on this reply type. miracle answers
    // requests in the order it received them, so the queue stays in step even
    // when several requests of the same type are in flight.
    final pending = payloadType == null ? null : _pendingResponses[payloadType];
    if (pending == null || pending.isEmpty) {
      _onUnknownMessage?.call(payloadTypeValue, payload);
      return;
    }
    pending.removeFirst().complete(payload);
    if (pending.isEmpty) _pendingResponses.remove(payloadType);
  }

  /// Handles event messages by parsing and emitting them to the stream
  void _handleEvent(IpcType type, String payload) {
    if (_eventController.isClosed) return;
    try {
      _eventController.add(Event.fromJson(type, jsonDecode(payload)));
    } catch (error, stackTrace) {
      // A malformed or unexpected payload must never tear down the stream.
      _eventController.addError(error, stackTrace);
    }
  }

  void _failPendingResponses(Object error, [StackTrace? stackTrace]) {
    final pending = _pendingResponses.values.toList(growable: false);
    _pendingResponses.clear();
    for (final queue in pending) {
      while (queue.isNotEmpty) {
        queue.removeFirst().completeError(error, stackTrace);
      }
    }
  }

  /// Sends a raw message using the i3-ipc protocol format:
  /// `<magic-string> <payload-length> <payload-type> <payload>`
  void _sendRawMessage(int payloadType, String payload) {
    final socket = _socket;
    if (socket == null) {
      throw MiracleConnectionException('Not connected');
    }

    final payloadBytes = utf8.encode(payload);
    final message = Uint8List(_headerSize + payloadBytes.length);
    final view = ByteData.sublistView(message);

    // Magic string: 'i3-ipc' (6 bytes)
    message.setRange(0, 6, utf8.encode(_ipcMagic));

    // Payload length and type as 32-bit integers in native byte order
    view.setUint32(6, payloadBytes.length, Endian.host);
    view.setUint32(10, payloadType, Endian.host);

    message.setRange(_headerSize, message.length, payloadBytes);
    socket.add(message);
  }

  /// Sends a message and waits for a response.
  /// Returns the response payload as a string.
  Future<String> _sendAndAwaitResponse(
    IpcType type,
    String payload, [
    IpcType? responseType,
  ]) {
    if (_socket == null) {
      throw MiracleConnectionException('Not connected');
    }

    final completer = Completer<String>();
    final queue = _pendingResponses.putIfAbsent(
      responseType ?? type,
      () => Queue<Completer<String>>(),
    );
    queue.add(completer);

    try {
      _sendRawMessage(type.value, payload);
    } catch (error, stackTrace) {
      queue.remove(completer);
      completer.completeError(error, stackTrace);
      return completer.future;
    }

    final timeout = _requestTimeout;
    if (timeout == null) return completer.future;
    return completer.future.timeout(timeout, onTimeout: () {
      queue.remove(completer);
      throw TimeoutException('miracle did not reply to $type', timeout);
    });
  }

  /// Sends the provided [command] string to the IPC server.
  ///
  /// Several commands may be sent at once by separating them with `;`, in
  /// which case one [CommandResult] is returned per command.
  ///
  /// Prefer [run] and [runAll], which build the command string for you.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<List<CommandResult>> command(String command) async {
    final response =
        await _sendAndAwaitResponse(IpcType.ipcCommand, command);
    return asObjectList(jsonDecode(response))
        .map(CommandResult.fromJson)
        .toList(growable: false);
  }

  /// Sends a single typed [command] to miracle.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<List<CommandResult>> run(MiracleCommand command) =>
      this.command(command.toCommandString());

  /// Sends every command in [commands] to miracle, in order.
  ///
  /// One [CommandResult] is returned per command.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<List<CommandResult>> runAll(Iterable<MiracleCommand> commands) =>
      command(joinCommands(commands));

  /// Sends [command] to miracle and throws if it did not succeed.
  ///
  /// Throws a [MiracleCommandException] when miracle reported a failure, and
  /// a [MiracleConnectionException] if not connected.
  Future<void> runOrThrow(MiracleCommand command) async {
    final string = command.toCommandString();
    final results = await this.command(string);
    if (results.any((result) => !result.success)) {
      throw MiracleCommandException(string, results);
    }
  }

  /// Gets the list of workspaces.
  ///
  /// Returns a list of [WorkspaceResult] objects containing information about
  /// all workspaces.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<List<WorkspaceResult>> getWorkspaces() async {
    final response =
        await _sendAndAwaitResponse(IpcType.ipcGetWorkspaces, '');
    return asObjectList(jsonDecode(response))
        .map(WorkspaceResult.fromJson)
        .toList(growable: false);
  }

  /// Gets the list of outputs.
  ///
  /// Returns a list of [OutputResult] objects describing every display that
  /// miracle knows about.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<List<OutputResult>> getOutputs() async {
    final response = await _sendAndAwaitResponse(IpcType.ipcGetOutputs, '');
    return asObjectList(jsonDecode(response))
        .map(OutputResult.fromJson)
        .toList(growable: false);
  }

  /// Gets the window tree structure.
  ///
  /// Returns the root [BaseNode] containing the entire tree of outputs,
  /// workspaces, and containers.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<BaseNode> getTree() async {
    final response = await _sendAndAwaitResponse(IpcType.ipcGetTree, '');
    return BaseNode.fromJson(asObject(jsonDecode(response)));
  }

  /// Gets the currently set marks.
  ///
  /// Returns the [MarksResult].
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<MarksResult> getMarks() async {
    final response = await _sendAndAwaitResponse(IpcType.ipcGetMarks, '');
    return MarksResult.fromJson(asList(jsonDecode(response)));
  }

  /// Gets the version information.
  ///
  /// Returns a [VersionResult] containing the version details.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<VersionResult> getVersion() async {
    final response = await _sendAndAwaitResponse(IpcType.ipcGetVersion, '');
    return VersionResult.fromJson(asObject(jsonDecode(response)));
  }

  /// Gets the list of binding modes.
  ///
  /// Returns a [BindingModesResult] containing the list of available binding
  /// modes. `default` is always among them.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<BindingModesResult> getBindingModes() async {
    final response =
        await _sendAndAwaitResponse(IpcType.ipcGetBindingModes, '');
    return BindingModesResult.fromJson(asList(jsonDecode(response)));
  }

  /// Gets the current binding state.
  ///
  /// Returns a [BindingStateResult] containing the name of the current
  /// binding state.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<BindingStateResult> getBindingState() async {
    final response =
        await _sendAndAwaitResponse(IpcType.ipcGetBindingState, '');
    return BindingStateResult.fromJson(asObject(jsonDecode(response)));
  }

  /// Gets a snapshot of miracle's debugging state.
  ///
  /// This is the data that powers the bundled debug overlay: the cursor
  /// position, the window underneath it, and every window across every output
  /// and workspace.
  ///
  /// Requires miracle v0.10.0 or newer.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<DebugState> getDebugState() async {
    final response = await _sendAndAwaitResponse(IpcType.ipcGetDebugState, '');
    return DebugState.fromJson(asObject(jsonDecode(response)));
  }

  /// Routes [payload] to the plugin that owns [plugin].
  ///
  /// The payload is handed to the plugin verbatim, and the plugin's own JSON
  /// response comes back in [PluginCommandResult.response].
  ///
  /// A namespace is owned by at most one plugin;
  /// [PluginCommandResult.success] is `false` when nobody owns [plugin], when
  /// the owning plugin has no command handler, or when the exchange was not
  /// valid JSON.
  ///
  /// See also:
  /// * [subscribeToPlugin], to receive events published by a plugin
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<PluginCommandResult> pluginCommand(
    String plugin, [
    Object? payload,
  ]) async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcPluginCommand,
      jsonEncode({'plugin': plugin, 'payload': payload}),
    );
    return PluginCommandResult.fromJson(asObject(jsonDecode(response)));
  }

  /// Sends a tick event to every client subscribed to ticks.
  ///
  /// This is most often used to know when miracle has drained everything sent
  /// before it: subscribe to [SubscriptionType.tick], send a tick, and wait
  /// for the [TickEvent] carrying [payload] back.
  ///
  /// [payload] is delivered to those clients as [TickEvent.payload]. A
  /// `String` is sent as-is; anything else is JSON encoded.
  ///
  /// Returns a [TickResult] which always contains `success: true`.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<TickResult> sendTick([Object? payload]) async {
    final encoded = switch (payload) {
      null => '',
      String string => string,
      _ => jsonEncode(payload),
    };
    final response =
        await _sendAndAwaitResponse(IpcType.ipcSendTick, encoded);
    return TickResult.fromJson(asObject(jsonDecode(response)));
  }

  /// Sends a sync request.
  ///
  /// Like sway, miracle does not implement i3's X11-specific sync, so this
  /// always returns a [SyncResult] with `name: "default"`.
  ///
  /// Throws a [MiracleConnectionException] if not connected.
  Future<SyncResult> sync() async {
    final response = await _sendAndAwaitResponse(IpcType.ipcSync, '');
    return SyncResult.fromJson(asObject(jsonDecode(response)));
  }

  /// Subscribes this connection to [events].
  ///
  /// Plugin events are subscribed to per namespace: pass the namespaces you
  /// are interested in as [pluginNamespaces]. A namespace must not collide
  /// with one of the built-in event names.
  ///
  /// Subscriptions accumulate, so calling this more than once adds to what
  /// the connection already receives. Subscribing to
  /// [SubscriptionType.tick] immediately delivers a [TickEvent] with
  /// [TickEvent.first] set, and subscribing to
  /// [SubscriptionType.configErrors] immediately delivers the errors of the
  /// most recent configuration load.
  ///
  /// Throws an [ArgumentError] if a namespace is a reserved event name, and a
  /// [MiracleConnectionException] if not connected.
  Future<SubscribeResult> subscribe(
    Iterable<SubscriptionType> events, {
    Iterable<String> pluginNamespaces = const [],
  }) async {
    for (final namespace in pluginNamespaces) {
      if (SubscriptionType.isReservedName(namespace)) {
        throw ArgumentError.value(
          namespace,
          'pluginNamespaces',
          'is the name of a built-in event and cannot be a plugin namespace',
        );
      }
    }

    final payload = jsonEncode([
      ...events.map((event) => event.wireName),
      ...pluginNamespaces,
    ]);
    final response =
        await _sendAndAwaitResponse(IpcType.ipcSubscribe, payload);
    return SubscribeResult.fromJson(asObject(jsonDecode(response)));
  }

  /// Subscribes this connection to the plugin events published on
  /// [namespace].
  ///
  /// See also:
  /// * [pluginEventsFor], to listen to that namespace
  /// * [pluginCommand], to send a command to the plugin
  Future<SubscribeResult> subscribeToPlugin(String namespace) =>
      subscribe(const [], pluginNamespaces: [namespace]);

  /// Subscribes this connection to every event miracle can send.
  ///
  /// Plugin namespaces are not included, as they have to be named
  /// individually; use [subscribeToPlugin] for those.
  Future<SubscribeResult> subscribeToAll() =>
      subscribe(SubscriptionType.values);
}

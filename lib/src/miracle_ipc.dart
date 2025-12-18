import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

/// IPC message types for i3/sway compatible IPC protocol
enum IpcType {
  // i3 command types - see i3's I3_REPLY_TYPE constants
  ipcCommand(0),
  ipcGetWorkspaces(1),
  ipcSubscribe(2),
  ipcGetOutputs(3),
  ipcGetTree(4),
  ipcGetMarks(5),

  /// Unused.
  ipcGetBarConfig(6),
  ipcGetVersion(7),
  ipcGetBindingModes(8),

  /// Unused.
  ipcGetConfig(9),
  ipcSendTick(10),
  ipcSync(11),
  ipcGetBindingState(12),

  // sway-specific command types
  /// Unused.
  ipcGetInputs(100),

  /// Unused.
  ipcGetSeats(101),

  // Events sent from sway to clients. Events have the highest bit set.
  ipcEventWorkspace(0x80000000 | 0),
  ipcEventOutput(0x80000000 | 1),
  ipcEventMode(0x80000000 | 2),
  ipcEventWindow(0x80000000 | 3),

  /// Unused.
  ipcEventBarconfigUpdate(0x80000000 | 4),
  ipcEventBinding(0x80000000 | 5),
  ipcEventShutdown(0x80000000 | 6),
  ipcEventTick(0x80000000 | 7),

  // sway-specific event types
  /// Unused.
  ipcEventBarStateUpdate(0x80000000 | 20),

  /// Unused.
  ipcEventInput(0x80000000 | 21);

  const IpcType(this.value);
  final int value;

  /// Creates an IpcType from an integer value
  static IpcType? fromValue(int value) {
    for (final type in IpcType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}

enum SubscribeEvent {
  workspace,
  output,
  mode,
  window,
  binding,
  shutdown,
  tick,
  input,
}

class CommandResponse {
  final bool success;
  final String? parseError;
  final String? error;

  CommandResponse({required this.success, this.parseError, this.error});
}

class SubscribeResponse {
  final bool success;
  final String? error;

  SubscribeResponse({required this.success, this.error});
}

class Rect {
  final int x;
  final int y;
  final int width;
  final int height;

  Rect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory Rect.fromJson(Map<String, dynamic> json) {
    return Rect(
      x: json['x'] as int,
      y: json['y'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }
}

class WorkspaceResponse {
  final int num;
  final String name;
  final bool visible;
  final bool focused;
  final bool urgent;
  final String output;
  final Rect rect;

  WorkspaceResponse({
    required this.num,
    required this.name,
    required this.visible,
    required this.focused,
    required this.urgent,
    required this.output,
    required this.rect,
  });

  factory WorkspaceResponse.fromJson(Map<String, dynamic> json) {
    return WorkspaceResponse(
      num: json['num'] as int,
      name: json['name'] as String,
      visible: json['visible'] as bool,
      focused: json['focused'] as bool,
      urgent: json['urgent'] as bool,
      output: json['output'] as String,
      rect: Rect.fromJson(json['rect'] as Map<String, dynamic>),
    );
  }
}

enum NodeType {
  root,
  output,
  workspace,
  container;

  static NodeType? fromString(String value) {
    switch (value) {
      case 'root':
        return NodeType.root;
      case 'output':
        return NodeType.output;
      case 'workspace':
        return NodeType.workspace;
      case 'con':
        return NodeType.container;
      default:
        return null;
    }
  }
}

enum OutputTransform {
  normal,
  ninety,
  oneeighty,
  twoseventy;

  static OutputTransform? fromString(String transform) {
    if (transform == 'normal') {
      return OutputTransform.normal;
    } else if (transform == '90') {
      return OutputTransform.ninety;
    } else if (transform == '180') {
      return OutputTransform.oneeighty;
    } else if (transform == '270') {
      return OutputTransform.twoseventy;
    }

    return null;
  }
}

enum BorderType {
  none,
  normal;

  static BorderType? fromString(String type) {
    switch (type) {
      case 'none':
        return BorderType.none;
      case 'normal':
        return BorderType.normal;
      default:
        return null;
    }
  }
}

enum ContainerLayout {
  splith,
  splitv,
  stacking,
  tabbed,
  none;

  static ContainerLayout? fromString(String layout) {
    switch (layout) {
      case 'splith':
        return ContainerLayout.splith;
      case 'splitv':
        return ContainerLayout.splitv;
      case 'stacking':
        return ContainerLayout.stacking;
      case 'tabbed':
        return ContainerLayout.tabbed;
      case 'none':
        return ContainerLayout.none;
      default:
        return null;
    }
  }
}

class OutputMode {
  final int width;
  final int height;
  final double refreshMhz;

  OutputMode(
      {required this.width, required this.height, required this.refreshMhz});

  factory OutputMode.fromJson(Map<String, dynamic> json) {
    return OutputMode(
        width: json['width'] as int,
        height: json['height'] as int,
        refreshMhz: json['refresh'] as double);
  }
}

sealed class TreeResponseNode {
  final int id;
  final String name;
  final Rect rect;
  final NodeType type;

  TreeResponseNode(
      {required this.id,
      required this.name,
      required this.rect,
      required this.type});

  String treeString([int depth = 0]);

  @override
  String toString() => treeString(0);

  factory TreeResponseNode.fromJson(Map<String, dynamic> json) {
    final NodeType? type = NodeType.fromString(json['type'] as String);
    if (type == null) {
      throw Exception('Unknown node type: ${json['type']}');
    }

    List<TreeResponseNode> nodes = [];
    if (json['nodes'] != null) {
      for (final node in json['nodes'] as List<dynamic>) {
        nodes.add(TreeResponseNode.fromJson(node));
      }
    }

    List<TreeResponseNode> floatingNodes = [];
    if (json['floating_nodes'] != null) {
      for (final node in json['floating_nodes'] as List<dynamic>) {
        floatingNodes.add(TreeResponseNode.fromJson(node));
      }
    }

    final id = json['id'] as int;
    final name = json['name'] as String;
    final rect = Rect.fromJson(json['rect'] as Map<String, dynamic>);

    switch (type) {
      case NodeType.root:
        return RootResponseNode(
          id: id,
          name: name,
          rect: rect,
          nodes: nodes,
          type: type,
        );
      case NodeType.output:
        return OutputResponseNode(
            id: id,
            name: name,
            rect: rect,
            nodes: nodes,
            type: type,
            active: json['active'] as bool,
            dpkms: json['dpkms'] as bool?,
            scale: json['scale'] as double,
            scaleFilter: json['scale_filter'],
            adaptiveSyncStatus: json['adaptive_sync_status'] as bool,
            make: json['make'],
            model: json['model'],
            serial: json['serial'],
            transform: OutputTransform.fromString(json['transform'])!,
            layout: json['layout'],
            orientation: json['orientation'],
            visible: json['visible'] as bool,
            isFocused: json['focused'] as bool,
            isUrgent: json['urgent'] as bool,
            border: BorderType.fromString(json['border'])!,
            borderWidth: json['current_border_width'] as int,
            windowRect: Rect.fromJson(json['window_rect']),
            decoRect: Rect.fromJson(json['deco_rect']),
            geometry: Rect.fromJson(json['geometry']),
            modes: (json['modes'] as List<dynamic>).map((final elementJson) {
              return OutputMode.fromJson(elementJson);
            }).toList(),
            currentMode: OutputMode.fromJson(json['current_mode']));
      case NodeType.workspace:
        return WorkspaceResponseNode(
          id: id,
          name: name,
          rect: rect,
          type: type,
          num: json['num'] as int,
          visible: json['visible'] as bool,
          focused: json['focused'] as bool,
          urgent: json['urgent'] as bool,
          output: json['output'] as String,
          border: BorderType.fromString(json['border'])!,
          borderWidth: json['current_border_width'] as int,
          layout: ContainerLayout.fromString(json['layout'] as String)!,
          orientation: json['orientation'] as String,
          windowRect:
              Rect.fromJson(json['window_rect'] as Map<String, dynamic>),
          decoRect: Rect.fromJson(json['deco_rect'] as Map<String, dynamic>),
          geometry: Rect.fromJson(json['geometry'] as Map<String, dynamic>),
          floatingNodes: floatingNodes,
          nodes: nodes,
        );
      case NodeType.container:
        return ContainerResponseNode(
          id: id,
          name: name,
          rect: rect,
          type: type,
          focused: json['focused'] as bool,
          focus: (json['focus'] as List<dynamic>).cast<int>(),
          border: BorderType.fromString(json['border'])!,
          borderWidth: json['current_border_width'] as int,
          layout: ContainerLayout.fromString(json['layout'] as String)!,
          orientation: json['orientation'] as String,
          percent: json['percent'] as double?,
          windowRect:
              Rect.fromJson(json['window_rect'] as Map<String, dynamic>),
          decoRect: Rect.fromJson(json['deco_rect'] as Map<String, dynamic>),
          geometry: Rect.fromJson(json['geometry'] as Map<String, dynamic>),
          window: json['window'] as int?,
          urgent: json['urgent'] as bool,
          floatingNodes: floatingNodes,
          sticky: json['sticky'] as bool,
          fullscreenMode: json['fullscreen_mode'] as int,
          pid: json['pid'] as int?,
          appId: json['app_id'] as String?,
          visible: json['visible'] as bool,
          shell: json['shell'] as String,
          inhibitIdle: json['inhibit_idle'] as bool,
          idleInhibitors: json['idle_inhibitors'],
          windowProperties: json['window_properties'] as Map<String, dynamic>,
          nodes: nodes,
          scratchpadState: json['scratchpad_state'] as String?,
        );
    }
  }
}

class RootResponseNode extends TreeResponseNode {
  final List<TreeResponseNode> nodes;

  RootResponseNode(
      {required super.id,
      required super.name,
      required super.rect,
      required super.type,
      required this.nodes});

  @override
  String treeString([int depth = 0]) {
    final indent = '  ' * depth;
    final rectStr = '(${rect.x}, ${rect.y}, ${rect.width}x${rect.height})';
    final buffer = StringBuffer();
    buffer.writeln('$indent[ROOT] id=$id, name="$name", rect=$rectStr');
    for (var child in nodes) {
      buffer.write(child.treeString(depth + 1));
    }
    return buffer.toString();
  }
}

class OutputResponseNode extends TreeResponseNode {
  final bool active;
  final bool? dpkms;
  final double scale;
  final String scaleFilter;
  final bool adaptiveSyncStatus;
  final String make;
  final String model;
  final String serial;
  final OutputTransform transform;
  final String layout;
  final String orientation;
  final bool visible;
  final bool isFocused;
  final bool isUrgent;
  final BorderType border;
  final int borderWidth;
  final Rect windowRect;
  final Rect decoRect;
  final Rect geometry;
  final List<TreeResponseNode> nodes;
  final List<OutputMode> modes;
  final OutputMode currentMode;

  OutputResponseNode({
    required super.id,
    required super.name,
    required super.rect,
    required super.type,
    required this.active,
    required this.dpkms,
    required this.scale,
    required this.scaleFilter,
    required this.adaptiveSyncStatus,
    required this.make,
    required this.model,
    required this.serial,
    required this.transform,
    required this.layout,
    required this.orientation,
    required this.visible,
    required this.isFocused,
    required this.isUrgent,
    required this.border,
    required this.borderWidth,
    required this.windowRect,
    required this.decoRect,
    required this.geometry,
    required this.nodes,
    required this.modes,
    required this.currentMode,
  });

  @override
  String treeString([int depth = 0]) {
    final indent = '  ' * depth;
    final rectStr = '(${rect.x}, ${rect.y}, ${rect.width}x${rect.height})';
    final buffer = StringBuffer();
    buffer.writeln('$indent[OUTPUT] id=$id, name="$name", active=$active, '
        'scale=$scale, rect=$rectStr');
    for (var child in nodes) {
      buffer.write(child.treeString(depth + 1));
    }
    return buffer.toString();
  }
}

class WorkspaceResponseNode extends TreeResponseNode {
  final int num;
  final bool visible;
  final bool focused;
  final bool urgent;
  final String output;
  final BorderType border;
  final int borderWidth;
  final ContainerLayout layout;
  final String orientation;
  final Rect windowRect;
  final Rect decoRect;
  final Rect geometry;
  final List<TreeResponseNode> floatingNodes;
  final List<TreeResponseNode> nodes;

  WorkspaceResponseNode({
    required super.id,
    required super.name,
    required super.rect,
    required super.type,
    required this.num,
    required this.visible,
    required this.focused,
    required this.urgent,
    required this.output,
    required this.border,
    required this.borderWidth,
    required this.layout,
    required this.orientation,
    required this.windowRect,
    required this.decoRect,
    required this.geometry,
    required this.floatingNodes,
    required this.nodes,
  });

  @override
  String treeString([int depth = 0]) {
    final indent = '  ' * depth;
    final rectStr = '(${rect.x}, ${rect.y}, ${rect.width}x${rect.height})';
    final buffer = StringBuffer();
    buffer.writeln('$indent[WORKSPACE] id=$id, name="$name", num=$num, '
        'layout=${layout.name}, focused=$focused, visible=$visible, output=$output, rect=$rectStr');
    if (floatingNodes.isNotEmpty) {
      buffer.writeln('$indent  Floating nodes:');
      for (var child in floatingNodes) {
        buffer.write(child.treeString(depth + 2));
      }
    }
    for (var child in nodes) {
      buffer.write(child.treeString(depth + 1));
    }
    return buffer.toString();
  }
}

class ContainerResponseNode extends TreeResponseNode {
  final bool focused;
  final List<int> focus;
  final BorderType border;
  final int borderWidth;
  final ContainerLayout layout;
  final String orientation;
  final double? percent;
  final Rect windowRect;
  final Rect decoRect;
  final Rect geometry;
  final int? window;
  final bool urgent;
  final List<TreeResponseNode> floatingNodes;
  final bool sticky;
  final int fullscreenMode;
  final int? pid;
  final String? appId;
  final bool visible;
  final String shell;
  final bool inhibitIdle;
  final dynamic idleInhibitors;
  final Map<String, dynamic> windowProperties;
  final List<TreeResponseNode> nodes;
  final String? scratchpadState;

  ContainerResponseNode({
    required super.id,
    required super.name,
    required super.rect,
    required super.type,
    required this.focused,
    required this.focus,
    required this.border,
    required this.borderWidth,
    required this.layout,
    required this.orientation,
    this.percent,
    required this.windowRect,
    required this.decoRect,
    required this.geometry,
    this.window,
    required this.urgent,
    required this.floatingNodes,
    required this.sticky,
    required this.fullscreenMode,
    this.pid,
    this.appId,
    required this.visible,
    required this.shell,
    required this.inhibitIdle,
    required this.idleInhibitors,
    required this.windowProperties,
    required this.nodes,
    this.scratchpadState,
  });

  @override
  String treeString([int depth = 0]) {
    final indent = '  ' * depth;
    final rectStr = '(${rect.x}, ${rect.y}, ${rect.width}x${rect.height})';
    final windowInfo = window != null ? ', window=$window' : '';
    final pidInfo = pid != null ? ', pid=$pid' : '';
    final appIdInfo = appId != null ? ', app_id="$appId"' : '';
    final buffer = StringBuffer();
    buffer.writeln('$indent[CONTAINER] id=$id, name="$name", '
        'layout=${layout.name}, focused=$focused$windowInfo$pidInfo$appIdInfo, rect=$rectStr');
    if (floatingNodes.isNotEmpty) {
      buffer.writeln('$indent  Floating nodes:');
      for (var child in floatingNodes) {
        buffer.write(child.treeString(depth + 2));
      }
    }
    for (var child in nodes) {
      buffer.write(child.treeString(depth + 1));
    }
    return buffer.toString();
  }
}

class _PendingResponse {
  final Completer<String> completer;
  final IpcType type;

  _PendingResponse({required this.completer, required this.type});
}

class MarksResponse {
  final List<String> marks;

  MarksResponse({required this.marks});
}

/// The version payload.
class VersionResponse {
  final int major;
  final int minor;
  final int patch;
  final String humanReadable;
  final String loadedConfigFilename;

  VersionResponse(
      {required this.major,
      required this.minor,
      required this.patch,
      required this.humanReadable,
      required this.loadedConfigFilename});

  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
        major: json['major'] as int,
        minor: json['minor'] as int,
        patch: json['patch'] as int,
        humanReadable: json['human_readable'] as String,
        loadedConfigFilename: json['loaded_config_file_name'] as String);
  }

  @override
  String toString() {
    return 'VersionResponse(major: $major, minor: $minor, patch: $patch, '
        'humanReadable: "$humanReadable", loadedConfigFilename: "$loadedConfigFilename")';
  }
}

class BindingModesResponse {
  final List<String> modes;

  BindingModesResponse({required this.modes});

  @override
  String toString() {
    return 'BindingModesResponse(modes: $modes)';
  }
}

class BindingStateResponse {
  final String name;

  BindingStateResponse({required this.name});

  factory BindingStateResponse.fromJson(Map<String, dynamic> json) {
    return BindingStateResponse(name: json['name'] as String);
  }

  @override
  String toString() {
    return 'BindingStateResponse(name: "$name")';
  }
}

class TickResponse {
  final bool success;

  TickResponse({required this.success});

  factory TickResponse.fromJson(Map<String, dynamic> json) {
    return TickResponse(success: json['success'] as bool);
  }

  @override
  String toString() {
    return 'TickResponse(success: $success)';
  }
}

class SyncResponse {
  final String name;

  SyncResponse({required this.name});

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(name: json['name'] as String);
  }

  @override
  String toString() {
    return 'SyncResponse(name: "$name")';
  }
}

/// Checks if you are awesome. Spoiler: you are.
class MiracleConnection {
  static const String _ipcMagic = 'i3-ipc';
  static const int _headerSize =
      14; // 6 bytes magic + 4 bytes length + 4 bytes type

  Socket? _socket;
  StreamSubscription? _socketSubscription;
  final BytesBuilder _buffer = BytesBuilder();
  List<_PendingResponse> _pendingResponses = [];

  Future<void> connect() async {
    final socketPath = Platform.environment['MIRACLESOCK'];
    if (socketPath == null || socketPath.isEmpty) {
      throw Exception('MIRACLESOCK environment variable is not set');
    }

    _socket = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );
    _startListening();
  }

  void disconnect() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.close();
    _socket = null;
    _buffer.clear();
  }

  /// Starts listening for incoming messages from the socket
  void _startListening() {
    if (_socket == null) {
      throw Exception('Not connected');
    }

    _socketSubscription = _socket!.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  /// Handles incoming data from the socket
  void _onData(List<int> data) {
    _buffer.add(data);

    // Try to parse complete messages from the buffer
    while (true) {
      final bytes = _buffer.toBytes();

      // Need at least the header to proceed
      if (bytes.length < _headerSize) {
        break;
      }

      // Parse header
      final magicBytes = bytes.sublist(0, 6);
      final magic = utf8.decode(magicBytes);

      if (magic != _ipcMagic) {
        print('Invalid magic string: $magic');
        _buffer.clear();
        break;
      }

      // Read payload length (32-bit unsigned integer in native byte order)
      final lengthData = ByteData.sublistView(
        Uint8List.fromList(bytes.sublist(6, 10)),
      );
      final payloadLength = lengthData.getUint32(0, Endian.host);

      // Read payload type (32-bit unsigned integer in native byte order)
      final typeData = ByteData.sublistView(
        Uint8List.fromList(bytes.sublist(10, 14)),
      );
      final payloadTypeValue = typeData.getUint32(0, Endian.host);

      // Check if we have the complete message
      final totalMessageSize = _headerSize + payloadLength;
      if (bytes.length < totalMessageSize) {
        // Not enough data yet, wait for more
        break;
      }

      // Extract payload
      final payloadBytes = bytes.sublist(_headerSize, totalMessageSize);
      final payload = utf8.decode(payloadBytes);

      // Get the IpcType enum value
      final payloadType = IpcType.fromValue(payloadTypeValue);

      // Handle the complete message
      _handleMessage(payloadType, payloadTypeValue, payload);

      // Remove the processed message from the buffer
      _buffer.clear();
      if (bytes.length > totalMessageSize) {
        _buffer.add(bytes.sublist(totalMessageSize));
      }
    }
  }

  /// Handles a complete parsed message
  void _handleMessage(
    IpcType? payloadType,
    int payloadTypeValue,
    String payload,
  ) {
    // Check if there is a pending response waiting for this type
    List<_PendingResponse> toRemove = [];
    for (var i = 0; i < _pendingResponses.length; i++) {
      final pending = _pendingResponses[i];
      if (pending.type == payloadType) {
        pending.completer.complete(payload);
        toRemove.add(pending);
      }
    }
    _pendingResponses.removeWhere((p) => toRemove.contains(p));

    // TODO: Dispatch to appropriate handlers based on message type
  }

  /// Handles socket errors
  void _onError(error) {
    print('Socket error: $error');
  }

  /// Handles socket disconnection
  void _onDone() {
    print('Socket closed');
  }

  /// Sends a raw message using the i3-ipc protocol format:
  /// <magic-string> <payload-length> <payload-type> <payload>
  void _sendRawMessage(int payloadType, String payload) {
    if (_socket == null) {
      throw Exception('Not connected');
    }

    final payloadBytes = utf8.encode(payload);
    final payloadLength = payloadBytes.length;

    // Build the message buffer
    final buffer = BytesBuilder();

    // Add magic string: 'i3-ipc' (6 bytes)
    buffer.add(utf8.encode(_ipcMagic));

    // Add payload length as 32-bit integer in native byte order
    final lengthData = ByteData(4);
    lengthData.setUint32(0, payloadLength, Endian.host);
    buffer.add(lengthData.buffer.asUint8List());

    // Add payload type as 32-bit integer in native byte order
    final typeData = ByteData(4);
    typeData.setUint32(0, payloadType, Endian.host);
    buffer.add(typeData.buffer.asUint8List());

    // Add payload
    buffer.add(payloadBytes);

    // Send the complete message
    _socket!.add(buffer.toBytes());
  }

  /// Sends a message and waits for a response.
  /// Returns the response payload as a string.
  Future<String> _sendAndAwaitResponse(
    int payloadType,
    String payload,
    IpcType responseType,
  ) async {
    if (_socket == null) {
      throw Exception('Not connected');
    }

    _pendingResponses.add(
      _PendingResponse(completer: Completer<String>(), type: responseType),
    );
    _sendRawMessage(payloadType, payload);

    return _pendingResponses.last.completer.future;
  }

  /// Sends the provided command string to the IPC server.
  ///
  /// Throws an Exception if not connected.
  Future<List<CommandResponse>> command(String message) async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcCommand.value,
      message,
      IpcType.ipcCommand,
    );
    final List<dynamic> jsonResponse = jsonDecode(response);
    return jsonResponse.map((item) {
      return CommandResponse(
        success: item['success'] ?? false,
        parseError: item['parse_error'],
        error: item['error'],
      );
    }).toList();
  }

  /// Gets the list of workspaces.
  ///
  /// Returns a list of WorkspaceResponse objects containing information about
  /// all workspaces.
  ///
  /// Throws an Exception if not connected.
  Future<List<WorkspaceResponse>> getWorkspaces() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetWorkspaces.value,
      '',
      IpcType.ipcGetWorkspaces,
    );
    final List<dynamic> jsonResponse = jsonDecode(response);
    return jsonResponse.map((item) {
      return WorkspaceResponse.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  /// Gets the window tree structure.
  ///
  /// Returns the root TreeResponseNode containing the entire tree of outputs,
  /// workspaces, and containers.
  ///
  /// Throws an Exception if not connected.
  Future<TreeResponseNode> getTree() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetTree.value,
      '',
      IpcType.ipcGetTree,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return TreeResponseNode.fromJson(jsonResponse);
  }

  /// Gets the currently set marks.
  ///
  /// Returns the [MarksResponse].
  ///
  /// Throws an [Exception] if not connected.
  Future<MarksResponse> getMarks() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetMarks.value,
      '',
      IpcType.ipcGetMarks,
    );
    final List<dynamic> marks = jsonDecode(response);
    return MarksResponse(marks: marks.cast<String>());
  }

  /// Gets the version information.
  ///
  /// Returns a [VersionResponse] containing the version details.
  ///
  /// Throws an [Exception] if not connected.
  Future<VersionResponse> getVersion() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetVersion.value,
      '',
      IpcType.ipcGetVersion,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return VersionResponse.fromJson(jsonResponse);
  }

  /// Gets the list of binding modes.
  ///
  /// Returns a [BindingModesResponse] containing the list of available binding modes.
  ///
  /// Throws an [Exception] if not connected.
  Future<BindingModesResponse> getBindingModes() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetBindingModes.value,
      '',
      IpcType.ipcGetBindingModes,
    );
    final List<dynamic> modes = jsonDecode(response);
    return BindingModesResponse(modes: modes.cast<String>());
  }

  /// Gets the current binding state.
  ///
  /// Returns a [BindingStateResponse] containing the name of the current binding state.
  ///
  /// Throws an [Exception] if not connected.
  Future<BindingStateResponse> getBindingState() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetBindingState.value,
      '',
      IpcType.ipcGetBindingState,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return BindingStateResponse.fromJson(jsonResponse);
  }

  /// Sends a tick event.
  ///
  /// Returns a [TickResponse] which always contains `success: true`.
  ///
  /// Throws an [Exception] if not connected.
  Future<TickResponse> sendTick() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcSendTick.value,
      '',
      IpcType.ipcSendTick,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return TickResponse.fromJson(jsonResponse);
  }

  /// Sends a sync request.
  ///
  /// Returns a [SyncResponse] which always contains `name: "default"`.
  ///
  /// Throws an [Exception] if not connected.
  Future<SyncResponse> sync() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcSync.value,
      '',
      IpcType.ipcSync,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return SyncResponse.fromJson(jsonResponse);
  }

  Future<SubscribeResponse> subscribe(List<SubscribeEvent> events) async {
    final eventStrings = events.map((e) {
      switch (e) {
        case SubscribeEvent.workspace:
          return 'workspace';
        case SubscribeEvent.output:
          return 'output';
        case SubscribeEvent.mode:
          return 'mode';
        case SubscribeEvent.window:
          return 'window';
        case SubscribeEvent.binding:
          return 'binding';
        case SubscribeEvent.shutdown:
          return 'shutdown';
        case SubscribeEvent.tick:
          return 'tick';
        case SubscribeEvent.input:
          return 'input';
      }
    }).toList();

    final payload = jsonEncode(eventStrings);
    final response = await _sendAndAwaitResponse(
      IpcType.ipcSubscribe.value,
      payload,
      IpcType.ipcSubscribe,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);

    // For simplicity, assume subscription is always successful
    return SubscribeResponse(
      success: jsonResponse['success'] ?? false,
      error: jsonResponse['error'],
    );
  }
}

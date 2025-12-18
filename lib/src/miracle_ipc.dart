import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

/// IPC message types for miracle.
///
/// Callers should prefer using the methods on [MiracleConnection] to send
/// ipc commands.
///
/// See also:
/// * [MiracleConnection], a convenient wrapper around the raw miracle IPC
///   mechanism.
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

/// An event that can be subscribed to.
///
/// See also:
/// * [MiracleConnection.subscribe], the method to subscribe to events
enum SubscriptionType {
  workspace,
  output,
  mode,
  window,
  binding,
  shutdown,
  tick,
  input,
}

/// Created in response to a [MiracleConnection.command] call.
///
/// See also:
/// * [MiracleConnection.command], to send a command
class CommandResult {
  /// `true` if the command was issued, otherwise `false`.
  final bool success;

  /// A parse error, if any.
  ///
  /// This may be set when [success] is `true`.
  final String? parseError;

  /// A generic error, if any.
  ///
  /// This may be set when [success] is `true`.
  final String? error;

  CommandResult({required this.success, this.parseError, this.error});
}

/// Created in response to a [MiracleConnection.subscribe] call.
///
/// See also:
/// * [MiracleConnection.subscribe], to subscribe to an event
class SubscribeResult {
  final bool success;
  final String? error;

  SubscribeResult({required this.success, this.error});
}

/// A generic rectangle.
class Rect {
  /// The x coordinate.
  final int x;

  /// The y coordinate.
  final int y;

  /// The width.
  final int width;

  /// The height.
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

/// Created in response to the [MiracleConnection.getWorkspaces] call.
///
/// See also:
/// * [MiracleConnection.getWorkspaces], to list the available workspaces
class WorkspaceResult {
  /// The number of the workspace, if any.
  final int? num;

  /// The name of the workspace, if any.
  final String? name;

  /// `true` if the workspace is visible, otherwise `false`.
  final bool visible;

  /// `true` if the workspace is focused, otherwise `false`.
  final bool focused;

  /// `true` if the workspace is urgent, otherwise `false`.
  final bool urgent;

  /// The name of the output to which this workspace belongs.
  final String output;

  /// The rectangle of this workspace.
  final Rect rect;

  WorkspaceResult({
    required this.num,
    required this.name,
    required this.visible,
    required this.focused,
    required this.urgent,
    required this.output,
    required this.rect,
  });

  factory WorkspaceResult.fromJson(Map<String, dynamic> json) {
    return WorkspaceResult(
      num: json['num'] as int?,
      name: json['name'] as String?,
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

sealed class BaseNode {
  final int id;
  final String name;
  final Rect rect;
  final NodeType type;

  BaseNode(
      {required this.id,
      required this.name,
      required this.rect,
      required this.type});

  String treeString([int depth = 0]);

  @override
  String toString() => treeString(0);

  factory BaseNode.fromJson(Map<String, dynamic> json) {
    final NodeType? type = NodeType.fromString(json['type'] as String);
    if (type == null) {
      throw Exception('Unknown node type: ${json['type']}');
    }

    switch (type) {
      case NodeType.root:
        return RootNode.fromJson(json);
      case NodeType.output:
        return OutputNode.fromJson(json);
      case NodeType.workspace:
        return WorkspaceNode.fromJson(json);
      case NodeType.container:
        return ContainerNode.fromJson(json);
    }
  }
}

/// Represents the root node in the window tree hierarchy.
///
/// The root node is the topmost node in the tree and contains all outputs.
/// There is only one root node per connection.
///
/// See also:
/// * [MiracleConnection.getTree], to retrieve the window tree
/// * [OutputNode], the type of nodes contained in the root
class RootNode extends BaseNode {
  /// The list of child nodes, typically [OutputNode] instances.
  final List<BaseNode> nodes;

  RootNode(
      {required super.id,
      required super.name,
      required super.rect,
      required super.type,
      required this.nodes});

  factory RootNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final rect = Rect.fromJson(json['rect'] as Map<String, dynamic>);
    final type = NodeType.fromString(json['type'] as String)!;

    List<BaseNode> nodes = [];
    if (json['nodes'] != null) {
      for (final node in json['nodes'] as List<dynamic>) {
        nodes.add(BaseNode.fromJson(node));
      }
    }

    return RootNode(
      id: id,
      name: name,
      rect: rect,
      type: type,
      nodes: nodes,
    );
  }

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

/// Represents a physical or virtual output (monitor/display) in the window tree.
///
/// Output nodes are children of the root node and contain workspace nodes.
/// Each output represents a display device with its own resolution, scale,
/// and other display properties.
///
/// See also:
/// * [RootNode], which contains output nodes
/// * [WorkspaceNode], the type of nodes contained in outputs
class OutputNode extends BaseNode {
  /// Whether the output is currently active.
  final bool active;

  /// Whether Display Power Management Signaling (DPMS) is enabled.
  final bool? dpkms;

  /// The scale factor for this output (e.g., 1.0, 1.5, 2.0).
  final double scale;

  /// The scaling filter used for this output.
  final String scaleFilter;

  /// Whether adaptive sync is enabled for this output.
  final bool adaptiveSyncStatus;

  /// The manufacturer name of the output device.
  final String make;

  /// The model name of the output device.
  final String model;

  /// The serial number of the output device.
  final String serial;

  /// The transform/rotation applied to this output.
  final OutputTransform transform;

  /// The layout name or configuration.
  final String layout;

  /// The orientation of the output.
  final String orientation;

  /// Whether the output is visible.
  final bool visible;

  /// Whether the output currently has focus.
  final bool isFocused;

  /// Whether the output is marked as urgent.
  final bool isUrgent;

  /// The border type for this output.
  final BorderType border;

  /// The width of the border in pixels.
  final int borderWidth;

  /// The window rectangle coordinates and dimensions.
  final Rect windowRect;

  /// The decoration rectangle coordinates and dimensions.
  final Rect decoRect;

  /// The geometry rectangle coordinates and dimensions.
  final Rect geometry;

  /// The list of child nodes, typically [WorkspaceNode] instances.
  final List<BaseNode> nodes;

  /// The list of available display modes for this output.
  final List<OutputMode> modes;

  /// The currently active display mode.
  final OutputMode currentMode;

  OutputNode({
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

  factory OutputNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final rect = Rect.fromJson(json['rect'] as Map<String, dynamic>);
    final type = NodeType.fromString(json['type'] as String)!;

    List<BaseNode> nodes = [];
    if (json['nodes'] != null) {
      for (final node in json['nodes'] as List<dynamic>) {
        nodes.add(BaseNode.fromJson(node));
      }
    }

    return OutputNode(
      id: id,
      name: name,
      rect: rect,
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
      currentMode: OutputMode.fromJson(json['current_mode']),
      nodes: nodes,
    );
  }

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

/// Represents a workspace in the window tree.
///
/// Workspaces are containers for windows and other containers. They are
/// children of output nodes and contain container nodes representing windows
/// and other UI elements.
///
/// See also:
/// * [OutputNode], which contains workspace nodes
/// * [ContainerNode], the type of nodes contained in workspaces
/// * [MiracleConnection.getWorkspaces], to list all workspaces
class WorkspaceNode extends BaseNode {
  /// The workspace number, if assigned.
  final int num;

  /// Whether the workspace is currently visible on its output.
  final bool visible;

  /// Whether the workspace currently has focus.
  final bool focused;

  /// Whether the workspace is marked as urgent.
  final bool urgent;

  /// The name of the output this workspace belongs to.
  final String output;

  /// The border type for this workspace.
  final BorderType border;

  /// The width of the border in pixels.
  final int borderWidth;

  /// The layout algorithm used for this workspace's children.
  final ContainerLayout layout;

  /// The orientation of the workspace layout.
  final String orientation;

  /// The window rectangle coordinates and dimensions.
  final Rect windowRect;

  /// The decoration rectangle coordinates and dimensions.
  final Rect decoRect;

  /// The geometry rectangle coordinates and dimensions.
  final Rect geometry;

  /// The list of floating nodes in this workspace.
  final List<BaseNode> floatingNodes;

  /// The list of tiled child nodes, typically [ContainerNode] instances.
  final List<BaseNode> nodes;

  WorkspaceNode({
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

  factory WorkspaceNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final rect = Rect.fromJson(json['rect'] as Map<String, dynamic>);
    final type = NodeType.fromString(json['type'] as String)!;

    List<BaseNode> nodes = [];
    if (json['nodes'] != null) {
      for (final node in json['nodes'] as List<dynamic>) {
        nodes.add(BaseNode.fromJson(node));
      }
    }

    List<BaseNode> floatingNodes = [];
    if (json['floating_nodes'] != null) {
      for (final node in json['floating_nodes'] as List<dynamic>) {
        floatingNodes.add(BaseNode.fromJson(node));
      }
    }

    return WorkspaceNode(
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
      windowRect: Rect.fromJson(json['window_rect'] as Map<String, dynamic>),
      decoRect: Rect.fromJson(json['deco_rect'] as Map<String, dynamic>),
      geometry: Rect.fromJson(json['geometry'] as Map<String, dynamic>),
      floatingNodes: floatingNodes,
      nodes: nodes,
    );
  }

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

/// Represents a container node in the window tree.
///
/// Container nodes represent windows, split containers, or other UI elements.
/// They are children of workspace nodes and can contain other container nodes,
/// forming a nested tree structure.
///
/// See also:
/// * [WorkspaceNode], which contains container nodes
class ContainerNode extends BaseNode {
  /// Whether this container currently has focus.
  final bool focused;

  /// The list of focused child node IDs within this container.
  final List<int> focus;

  /// The border type for this container.
  final BorderType border;

  /// The width of the border in pixels.
  final int borderWidth;

  /// The layout algorithm used for this container's children.
  final ContainerLayout layout;

  /// The orientation of the container layout.
  final String orientation;

  /// The percentage of parent space this container occupies, if applicable.
  final double? percent;

  /// The window rectangle coordinates and dimensions.
  final Rect windowRect;

  /// The decoration rectangle coordinates and dimensions.
  final Rect decoRect;

  /// The geometry rectangle coordinates and dimensions.
  final Rect geometry;

  /// The X11 window ID, if this is an X11 window.
  final int? window;

  /// Whether this container is marked as urgent.
  final bool urgent;

  /// The list of floating child nodes.
  final List<BaseNode> floatingNodes;

  /// Whether this container is sticky (visible on all workspaces).
  final bool sticky;

  /// The fullscreen mode state (0 for not fullscreen).
  final int fullscreenMode;

  /// The process ID of the application, if available.
  final int? pid;

  /// The application ID (typically for Wayland windows), if available.
  final String? appId;

  /// Whether this container is visible.
  final bool visible;

  /// The shell type (e.g., "xdg_shell", "xwayland").
  final String shell;

  /// Whether this container inhibits idle.
  final bool inhibitIdle;

  /// Information about idle inhibitors.
  final dynamic idleInhibitors;

  /// Additional window properties (X11-specific).
  final Map<String, dynamic> windowProperties;

  /// The list of child container nodes.
  final List<BaseNode> nodes;

  /// The scratchpad state, if this container is in the scratchpad.
  final String? scratchpadState;

  ContainerNode({
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

  factory ContainerNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final rect = Rect.fromJson(json['rect'] as Map<String, dynamic>);
    final type = NodeType.fromString(json['type'] as String)!;

    List<BaseNode> nodes = [];
    if (json['nodes'] != null) {
      for (final node in json['nodes'] as List<dynamic>) {
        nodes.add(BaseNode.fromJson(node));
      }
    }

    List<BaseNode> floatingNodes = [];
    if (json['floating_nodes'] != null) {
      for (final node in json['floating_nodes'] as List<dynamic>) {
        floatingNodes.add(BaseNode.fromJson(node));
      }
    }

    return ContainerNode(
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
      windowRect: Rect.fromJson(json['window_rect'] as Map<String, dynamic>),
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

/// Created in response to a [MiracleConnection.getMarks] call.
///
/// See also:
/// * [MiracleConnection.getMarks], to get the currently set marks
class MarksResult {
  /// The list of marks currently set.
  final List<String> marks;

  MarksResult({required this.marks});

  factory MarksResult.fromJson(List<dynamic> json) {
    return MarksResult(marks: json.cast<String>());
  }
}

/// Created in response to a [MiracleConnection.getVersion] call.
///
/// Contains version information about the running Miracle window manager.
///
/// See also:
/// * [MiracleConnection.getVersion], to get the version information
class VersionResult {
  /// The major version number.
  final int major;

  /// The minor version number.
  final int minor;

  /// The patch version number.
  final int patch;

  /// A human-readable version string.
  final String humanReadable;

  /// The path to the loaded configuration file.
  final String loadedConfigFilename;

  VersionResult(
      {required this.major,
      required this.minor,
      required this.patch,
      required this.humanReadable,
      required this.loadedConfigFilename});

  factory VersionResult.fromJson(Map<String, dynamic> json) {
    return VersionResult(
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

/// Created in response to a [MiracleConnection.getBindingModes] call.
///
/// See also:
/// * [MiracleConnection.getBindingModes], to get the list of available binding modes
class BindingModesResult {
  /// The list of available binding mode names.
  final List<String> modes;

  BindingModesResult({required this.modes});

  factory BindingModesResult.fromJson(List<dynamic> json) {
    return BindingModesResult(modes: json.cast<String>());
  }

  @override
  String toString() {
    return 'BindingModesResponse(modes: $modes)';
  }
}

/// Created in response to a [MiracleConnection.getBindingState] call.
///
/// See also:
/// * [MiracleConnection.getBindingState], to get the current binding state
/// * [MiracleConnection.getBindingModes], to get the available modes
class BindingStateResult {
  /// The name of the current binding state.
  ///
  /// This will be a mode found in[BindingModesResult].
  ///
  /// Use [MiracleConnection.getBindingModes] to list the available modes.
  final String name;

  BindingStateResult({required this.name});

  factory BindingStateResult.fromJson(Map<String, dynamic> json) {
    return BindingStateResult(name: json['name'] as String);
  }

  @override
  String toString() {
    return 'BindingStateResponse(name: "$name")';
  }
}

/// Created in response to a [MiracleConnection.sendTick] call.
///
/// See also:
/// * [MiracleConnection.sendTick], to send a tick event
class TickResult {
  /// Always `true` to indicate the tick was successfully sent.
  final bool success;

  TickResult({required this.success});

  factory TickResult.fromJson(Map<String, dynamic> json) {
    return TickResult(success: json['success'] as bool);
  }

  @override
  String toString() {
    return 'TickResponse(success: $success)';
  }
}

/// Created in response to a [MiracleConnection.sync] call.
///
/// See also:
/// * [MiracleConnection.sync], to send a sync request
class SyncResult {
  /// Always `"default"` to indicate the sync was successful.
  final String name;

  SyncResult({required this.name});

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(name: json['name'] as String);
  }

  @override
  String toString() {
    return 'SyncResponse(name: "$name")';
  }
}

sealed class Event {
  Event({required this.type});
  final IpcType type;

  factory Event.fromJson(IpcType type, Map<String, dynamic> json) {
    switch (type) {
      case IpcType.ipcEventWorkspace:
        return EventWorkspace(
            workspaceEventType:
                WorkspaceEventType.fromString(json['change'] as String),
            old: json['old'] != null
                ? WorkspaceNode.fromJson(json['old'])
                : null,
            current: WorkspaceNode.fromJson(json['current']));
      default:
        throw UnsupportedError('Unsupported event of type $type');
    }
  }

  @override
  String toString() {
    return 'Event(type: $type)';
  }
}

enum WorkspaceEventType {
  init,
  empty,
  focus,
  rename;

  factory WorkspaceEventType.fromString(String s) {
    return WorkspaceEventType.values.firstWhere((e) => e.name == s);
  }
}

class EventWorkspace extends Event {
  final WorkspaceEventType workspaceEventType;
  final WorkspaceNode? old;
  final WorkspaceNode current;

  EventWorkspace(
      {required this.workspaceEventType,
      required this.old,
      required this.current})
      : super(type: IpcType.ipcEventWorkspace);

  @override
  String toString() {
    return 'EventWorkspace(type: $type, workspaceEventType: $workspaceEventType, old: $old, current: $current)';
  }
}

/// A connection Miracle's IPC.
///
/// Callers may use the methods defined on the class to send requests to
/// Miracle.
///
/// Alternatively, callers may listen to events on miracle by first calling
/// [MiracleConnection.subscribe] and then listening on the stream.
///
/// Example:
/// ```dart
/// // Create a new connection
/// final connection = MiracleConnection();
///
/// // Connect to Miracle
/// await connection.connect();
///
/// // Send a command to switch to workspace 2
/// await connection.sendCommand('workspace 2');
///
/// // Subscribe to workspace events
/// await connection.subscribe(event: 'workspace');
///
/// // Listen to incoming events
/// await for (final event in connection) {
///   print('Received event: $event');
/// }
/// ```
class MiracleConnection extends Stream<Event> {
  static const String _ipcMagic = 'i3-ipc';
  static const int _headerSize =
      14; // 6 bytes magic + 4 bytes length + 4 bytes type

  Socket? _socket;
  StreamSubscription? _socketSubscription;
  final BytesBuilder _buffer = BytesBuilder();
  final List<_PendingResponse> _pendingResponses = [];
  final StreamController<Event> _eventController =
      StreamController<Event>.broadcast();

  /// Connect to Miracle's IPC socket.
  ///
  /// [onSocketError] will be called when there is an error on the connection.
  /// [onSocketDone] will be called when the connection is closed.
  ///
  /// Returns a future. Once the future resolves, the connection is established.
  ///
  /// This will thrown an [Exception] if the MIRACLESOCK environment variable
  /// cannot be found or if we cannot connect to the socket.
  Future<void> connect(
      {void Function()? onSocketError, void Function()? onSocketDone}) async {
    final socketPath = Platform.environment['MIRACLESOCK'];
    if (socketPath == null || socketPath.isEmpty) {
      throw Exception('MIRACLESOCK environment variable is not set');
    }

    _socket = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );
    _startListening(onSocketError, onSocketDone);
  }

  /// Disconnect from Miracle's IPC socket.
  void disconnect() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.close();
    _socket = null;
    _buffer.clear();
    _eventController.close();
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

  /// Starts listening for incoming messages from the socket
  void _startListening(
      void Function()? onSocketError, void Function()? onSocketDone) {
    if (_socket == null) {
      throw Exception('Not connected');
    }

    _socketSubscription = _socket!.listen(
      _onData,
      onError: onSocketError,
      onDone: onSocketDone,
      cancelOnError: false,
    );
  }

  /// Handles incoming data from the socket
  void _onData(List<int> data) {
    _buffer.add(data);

    while (true) {
      final bytes = _buffer.toBytes();
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
      final payloadType = IpcType.fromValue(payloadTypeValue);
      _handleMessage(payloadType, payloadTypeValue, payload);
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
    // Check if this is an event (high bit set)
    final isEvent = (payloadTypeValue & 0x80000000) != 0;

    if (isEvent) {
      // Handle event messages by emitting them to the stream
      if (payloadType != null) {
        _handleEvent(payloadType, payload);
      }
    } else {
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
    }
  }

  /// Handles event messages by parsing and emitting them to the stream
  void _handleEvent(IpcType type, String payload) {
    final Map<String, dynamic> jsonPayload = jsonDecode(payload);
    final event = Event.fromJson(type, jsonPayload);
    _eventController.add(event);
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

  /// Sends the provided [command] string to the IPC server.
  ///
  /// Throws an [Exception] if not connected.
  ///
  /// Returns a [CommandResult].
  Future<List<CommandResult>> command(String command) async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcCommand.value,
      command,
      IpcType.ipcCommand,
    );
    final List<dynamic> jsonResponse = jsonDecode(response);
    return jsonResponse.map((item) {
      return CommandResult(
        success: item['success'] ?? false,
        parseError: item['parse_error'],
        error: item['error'],
      );
    }).toList();
  }

  /// Gets the list of workspaces.
  ///
  /// Returns a list of [WorkspaceResult] objects containing information about
  /// all workspaces.
  ///
  /// Throws an [Exception] if not connected.
  Future<List<WorkspaceResult>> getWorkspaces() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetWorkspaces.value,
      '',
      IpcType.ipcGetWorkspaces,
    );
    final List<dynamic> jsonResponse = jsonDecode(response);
    return jsonResponse.map((item) {
      return WorkspaceResult.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  /// Gets the window tree structure.
  ///
  /// Returns the root [BaseNode] containing the entire tree of outputs,
  /// workspaces, and containers.
  ///
  /// Throws an [Exception] if not connected.
  Future<BaseNode> getTree() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetTree.value,
      '',
      IpcType.ipcGetTree,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return BaseNode.fromJson(jsonResponse);
  }

  /// Gets the currently set marks.
  ///
  /// Returns the [MarksResult].
  ///
  /// Throws an [Exception] if not connected.
  Future<MarksResult> getMarks() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetMarks.value,
      '',
      IpcType.ipcGetMarks,
    );
    final List<dynamic> marks = jsonDecode(response);
    return MarksResult.fromJson(marks);
  }

  /// Gets the version information.
  ///
  /// Returns a [VersionResult] containing the version details.
  ///
  /// Throws an [Exception] if not connected.
  Future<VersionResult> getVersion() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetVersion.value,
      '',
      IpcType.ipcGetVersion,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return VersionResult.fromJson(jsonResponse);
  }

  /// Gets the list of binding modes.
  ///
  /// Returns a [BindingModesResult] containing the list of available binding modes.
  ///
  /// Throws an [Exception] if not connected.
  Future<BindingModesResult> getBindingModes() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetBindingModes.value,
      '',
      IpcType.ipcGetBindingModes,
    );
    final List<dynamic> modes = jsonDecode(response);
    return BindingModesResult(modes: modes.cast<String>());
  }

  /// Gets the current binding state.
  ///
  /// Returns a [BindingStateResult] containing the name of the current binding state.
  ///
  /// Throws an [Exception] if not connected.
  Future<BindingStateResult> getBindingState() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcGetBindingState.value,
      '',
      IpcType.ipcGetBindingState,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return BindingStateResult.fromJson(jsonResponse);
  }

  /// Sends a tick event.
  ///
  /// Returns a [TickResult] which always contains `success: true`.
  ///
  /// Throws an [Exception] if not connected.
  Future<TickResult> sendTick() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcSendTick.value,
      '',
      IpcType.ipcSendTick,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return TickResult.fromJson(jsonResponse);
  }

  /// Sends a sync request.
  ///
  /// Returns a [SyncResult] which always contains `name: "default"`.
  ///
  /// Throws an [Exception] if not connected.
  Future<SyncResult> sync() async {
    final response = await _sendAndAwaitResponse(
      IpcType.ipcSync.value,
      '',
      IpcType.ipcSync,
    );
    final Map<String, dynamic> jsonResponse = jsonDecode(response);
    return SyncResult.fromJson(jsonResponse);
  }

  Future<SubscribeResult> subscribe(List<SubscriptionType> events) async {
    final eventStrings = events.map((e) {
      switch (e) {
        case SubscriptionType.workspace:
          return 'workspace';
        case SubscriptionType.output:
          return 'output';
        case SubscriptionType.mode:
          return 'mode';
        case SubscriptionType.window:
          return 'window';
        case SubscriptionType.binding:
          return 'binding';
        case SubscriptionType.shutdown:
          return 'shutdown';
        case SubscriptionType.tick:
          return 'tick';
        case SubscriptionType.input:
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
    return SubscribeResult(
      success: jsonResponse['success'] ?? false,
      error: jsonResponse['error'],
    );
  }
}

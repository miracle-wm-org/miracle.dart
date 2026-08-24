import 'geometry.dart';
import 'json.dart';
import 'miracle_ipc.dart';
import 'replies.dart';

/// The type of a node in the tree returned by `GET_TREE`.
enum NodeType {
  root('root'),
  output('output'),
  workspace('workspace'),
  container('con'),
  floatingContainer('floating_con');

  const NodeType(this.wireName);

  /// The name used on the wire, e.g. `floating_con`.
  final String wireName;

  static NodeType? fromString(String value) {
    for (final type in NodeType.values) {
      if (type.wireName == value) return type;
    }
    return null;
  }
}

/// The rotation applied to an output.
enum OutputTransform {
  normal('normal'),
  ninety('90'),
  oneeighty('180'),
  twoseventy('270'),
  flippedNinety('flipped-90'),
  flippedOneEighty('flipped-180'),
  flippedTwoSeventy('flipped-270');

  const OutputTransform(this.wireName);

  /// The name used on the wire, e.g. `flipped-90`.
  final String wireName;

  static OutputTransform? fromString(String transform) {
    for (final value in OutputTransform.values) {
      if (value.wireName == transform) return value;
    }
    return null;
  }

  /// Reads a transform from [json], or `null` when it is absent or unknown.
  static OutputTransform? parseOrNull(Object? json) {
    final value = asStringOrNull(json);
    return value == null ? null : fromString(value);
  }
}

/// The subpixel layout reported for an output.
enum SubpixelHinting {
  rgb('rgb'),
  bgr('bgr'),
  vrgb('vrgb'),
  vbgr('vbgr'),
  none('none');

  const SubpixelHinting(this.wireName);

  /// The name used on the wire.
  final String wireName;

  static SubpixelHinting? fromString(String value) {
    for (final hinting in SubpixelHinting.values) {
      if (hinting.wireName == value) return hinting;
    }
    return null;
  }

  /// Reads a hinting value from [json], or `null` when absent or unknown.
  static SubpixelHinting? parseOrNull(Object? json) {
    final value = asStringOrNull(json);
    return value == null ? null : fromString(value);
  }
}

/// The border style of a node.
enum BorderType {
  none('none'),
  normal('normal'),
  pixel('pixel'),
  csd('csd');

  const BorderType(this.wireName);

  /// The name used on the wire.
  final String wireName;

  static BorderType? fromString(String type) {
    for (final value in BorderType.values) {
      if (value.wireName == type) return value;
    }
    return null;
  }

  /// Reads a border from [json], falling back to [BorderType.none].
  static BorderType parse(Object? json) =>
      fromString(asString(json, 'none')) ?? BorderType.none;
}

/// The layout scheme in use on a node.
enum ContainerLayout {
  splith('splith'),
  splitv('splitv'),
  stacking('stacking'),
  tabbed('tabbed'),

  /// Reported by output nodes, whose children are workspaces.
  output('output'),
  none('none');

  const ContainerLayout(this.wireName);

  /// The name used on the wire.
  final String wireName;

  static ContainerLayout? fromString(String layout) {
    for (final value in ContainerLayout.values) {
      if (value.wireName == layout) return value;
    }
    return null;
  }

  /// Reads a layout from [json], falling back to [ContainerLayout.none].
  static ContainerLayout parse(Object? json) =>
      fromString(asString(json, 'none')) ?? ContainerLayout.none;
}

/// Where a container sits with respect to the scratchpad.
enum ScratchpadState {
  /// The container is not on the scratchpad.
  none('none'),

  /// The container was moved to the scratchpad and has not been shown yet.
  fresh('fresh'),

  /// The container has been shown, moved or resized since being stashed.
  changed('changed'),
  unknown('unknown');

  const ScratchpadState(this.wireName);

  /// The name used on the wire.
  final String wireName;

  static ScratchpadState? fromString(String value) {
    for (final state in ScratchpadState.values) {
      if (state.wireName == value) return state;
    }
    return null;
  }

  /// Reads a scratchpad state from [json], or `null` when it is absent.
  static ScratchpadState? parseOrNull(Object? json) {
    final value = asStringOrNull(json);
    return value == null ? null : fromString(value);
  }
}

/// A display mode supported by an output.
class OutputMode {
  /// The width, in pixels.
  final int width;

  /// The height, in pixels.
  final int height;

  /// The refresh rate, in millihertz.
  final double refreshMhz;

  const OutputMode({
    required this.width,
    required this.height,
    required this.refreshMhz,
  });

  factory OutputMode.fromJson(Map<String, dynamic> json) {
    return OutputMode(
      width: asInt(json['width']),
      height: asInt(json['height']),
      refreshMhz: asDouble(json['refresh']),
    );
  }

  /// Reads a mode from [json], or `null` when it is absent.
  static OutputMode? parseOrNull(Object? json) {
    final object = asObjectOrNull(json);
    return object == null ? null : OutputMode.fromJson(object);
  }

  /// Reads a list of modes from [json].
  static List<OutputMode> parseList(Object? json) =>
      asObjectList(json).map(OutputMode.fromJson).toList(growable: false);

  /// The refresh rate, in hertz.
  double get refreshHz => refreshMhz / 1000;

  /// The size of this mode.
  Size get size => Size(width: width, height: height);

  @override
  bool operator ==(Object other) =>
      other is OutputMode &&
      other.width == width &&
      other.height == height &&
      other.refreshMhz == refreshMhz;

  @override
  int get hashCode => Object.hash(width, height, refreshMhz);

  @override
  String toString() =>
      'OutputMode(${width}x$height@${refreshHz.toStringAsFixed(3)}Hz)';
}

/// The idle inhibitors applied to a container.
class IdleInhibitors {
  /// The application-requested inhibitor, e.g. `none`.
  final String? application;

  /// The user-requested inhibitor, e.g. `visible`.
  final String? user;

  const IdleInhibitors({this.application, this.user});

  factory IdleInhibitors.fromJson(Map<String, dynamic> json) => IdleInhibitors(
        application: asStringOrNull(json['application']),
        user: asStringOrNull(json['user']),
      );

  /// Reads idle inhibitors from [json], or `null` when they are absent.
  static IdleInhibitors? parseOrNull(Object? json) {
    final object = asObjectOrNull(json);
    return object == null ? null : IdleInhibitors.fromJson(object);
  }

  @override
  String toString() => 'IdleInhibitors(application: $application, user: $user)';
}

/// Arbitrary properties reported for a window.
///
/// miracle does not populate these yet, so [raw] is generally empty.
class WindowProperties {
  /// The X11 class of the window, if any.
  final String? className;

  /// The X11 instance of the window, if any.
  final String? instance;

  /// The window this one is transient for, if any.
  final String? transientFor;

  /// Every property exactly as it was received.
  final Map<String, dynamic> raw;

  const WindowProperties({
    this.className,
    this.instance,
    this.transientFor,
    this.raw = const {},
  });

  factory WindowProperties.fromJson(Map<String, dynamic> json) =>
      WindowProperties(
        className: asStringOrNull(json['class']),
        instance: asStringOrNull(json['instance']),
        transientFor: asStringOrNull(json['transient_for']),
        raw: json,
      );

  /// Reads window properties from [json], falling back to an empty instance.
  static WindowProperties parse(Object? json) =>
      WindowProperties.fromJson(asObject(json));

  /// Whether any property was reported.
  bool get isEmpty => raw.isEmpty;

  @override
  String toString() => 'WindowProperties($raw)';
}

/// A node in the tree returned by `GET_TREE`.
///
/// Every node is one of [RootNode], [OutputNode], [WorkspaceNode] or
/// [ContainerNode], which makes it exhaustively switchable:
///
/// ```dart
/// final label = switch (node) {
///   RootNode() => 'root',
///   OutputNode(:final make) => 'output by $make',
///   WorkspaceNode(:final num) => 'workspace $num',
///   ContainerNode(:final appId) => appId ?? 'container',
/// };
/// ```
sealed class BaseNode {
  /// A unique identifier for this node.
  final int id;

  /// The name of this node.
  final String name;

  /// The absolute display coordinates of this node.
  final Rect rect;

  /// The type of this node.
  final NodeType type;

  BaseNode({
    required this.id,
    required this.name,
    required this.rect,
    required this.type,
  });

  /// The tiled children of this node.
  List<BaseNode> get nodes;

  /// The floating children of this node.
  List<BaseNode> get floatingNodes;

  String treeString([int depth = 0]);

  @override
  String toString() => treeString(0);

  factory BaseNode.fromJson(Map<String, dynamic> json) {
    final NodeType? type = NodeType.fromString(asString(json['type']));
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
      case NodeType.floatingContainer:
        return ContainerNode.fromJson(json);
    }
  }

  /// Reads the child nodes stored under [key] of [json].
  static List<BaseNode> parseChildren(Map<String, dynamic> json, String key) =>
      asObjectList(json[key]).map(BaseNode.fromJson).toList(growable: false);

  /// Every tiled and floating child of this node.
  List<BaseNode> get children => [...nodes, ...floatingNodes];

  /// This node followed by every one of its descendants, depth first.
  Iterable<BaseNode> walk() sync* {
    yield this;
    for (final child in children) {
      yield* child.walk();
    }
  }

  /// Every descendant of this node, depth first.
  Iterable<BaseNode> get descendants => walk().skip(1);

  /// The node with the given [id], searched depth first, or `null`.
  BaseNode? findById(int id) {
    for (final node in walk()) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// Every output at or below this node.
  Iterable<OutputNode> get outputs => walk().whereType<OutputNode>();

  /// Every workspace at or below this node.
  Iterable<WorkspaceNode> get workspaces => walk().whereType<WorkspaceNode>();

  /// Every container that holds an actual window at or below this node.
  ///
  /// Split containers, which merely group other containers, are skipped.
  Iterable<ContainerNode> get windows =>
      walk().whereType<ContainerNode>().where((node) => node.isWindow);

  /// The focused node at or below this node, or `null` if none is focused.
  BaseNode? get focusedNode {
    for (final node in walk()) {
      final focused = switch (node) {
        RootNode() => false,
        OutputNode(:final isFocused) => isFocused,
        WorkspaceNode(:final focused) => focused,
        ContainerNode(:final focused) => focused,
      };
      if (focused) return node;
    }
    return null;
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
  @override
  final List<BaseNode> nodes;

  @override
  List<BaseNode> get floatingNodes => const [];

  RootNode({
    required super.id,
    required super.name,
    required super.rect,
    required super.type,
    required this.nodes,
  });

  factory RootNode.fromJson(Map<String, dynamic> json) {
    return RootNode(
      id: asInt(json['id']),
      name: asString(json['name']),
      rect: Rect.parse(json['rect']),
      type: NodeType.root,
      nodes: BaseNode.parseChildren(json, 'nodes'),
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
/// * [OutputResult], the flat representation returned by `GET_OUTPUTS`
class OutputNode extends BaseNode {
  /// Whether the output is currently active.
  final bool active;

  /// Whether the output is powered on.
  final bool? dpms;

  /// The scale factor for this output (e.g., 1.0, 1.5, 2.0).
  final double scale;

  /// The scaling filter used for this output.
  ///
  /// Supplied but unused by miracle, and always `linear`.
  final String scaleFilter;

  /// Whether adaptive sync is enabled for this output.
  ///
  /// Supplied but unused by miracle, and always `false`.
  final bool adaptiveSyncStatus;

  /// The manufacturer name of the output device.
  final String make;

  /// The model name of the output device.
  final String model;

  /// The serial number of the output device.
  final String serial;

  /// The transform/rotation applied to this output.
  final OutputTransform transform;

  /// The layout of this output, which is always [ContainerLayout.output].
  final ContainerLayout layout;

  /// The orientation of the output.
  ///
  /// Deprecated by miracle, and always `none`.
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
  @override
  final List<BaseNode> nodes;

  @override
  List<BaseNode> get floatingNodes => const [];

  /// The list of available display modes for this output.
  final List<OutputMode> modes;

  /// The currently active display mode, if the output reported one.
  final OutputMode? currentMode;

  OutputNode({
    required super.id,
    required super.name,
    required super.rect,
    required super.type,
    required this.active,
    required this.dpms,
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
    return OutputNode(
      id: asInt(json['id']),
      name: asString(json['name']),
      rect: Rect.parse(json['rect']),
      type: NodeType.output,
      active: asBool(json['active']),
      // miracle emits `dpms`; the wiki spells the tree field `dpkms`.
      dpms: asBoolOrNull(json['dpms'] ?? json['dpkms']),
      scale: asDouble(json['scale'], 1),
      scaleFilter: asString(json['scale_filter'], 'linear'),
      adaptiveSyncStatus: asBool(json['adaptive_sync_status']),
      make: asString(json['make'], 'Unknown'),
      model: asString(json['model'], 'Unknown'),
      serial: asString(json['serial'], 'Unknown'),
      transform:
          OutputTransform.parseOrNull(json['transform']) ?? OutputTransform.normal,
      layout: ContainerLayout.parse(json['layout']),
      orientation: asString(json['orientation'], 'none'),
      visible: asBool(json['visible']),
      isFocused: asBool(json['focused']),
      isUrgent: asBool(json['urgent']),
      border: BorderType.parse(json['border']),
      borderWidth: asInt(json['current_border_width']),
      windowRect: Rect.parse(json['window_rect']),
      decoRect: Rect.parse(json['deco_rect']),
      geometry: Rect.parse(json['geometry']),
      modes: OutputMode.parseList(json['modes']),
      currentMode: OutputMode.parseOrNull(json['current_mode']),
      nodes: BaseNode.parseChildren(json, 'nodes'),
    );
  }

  /// Whether Display Power Management Signaling (DPMS) is enabled.
  @Deprecated('miracle reports this as `dpms`. Use OutputNode.dpms instead.')
  bool? get dpkms => dpms;

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
  /// The workspace number, or `-1` for workspaces without one.
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
  @override
  final List<BaseNode> floatingNodes;

  /// The list of tiled child nodes, typically [ContainerNode] instances.
  @override
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
    return WorkspaceNode(
      id: asInt(json['id']),
      name: asString(json['name']),
      rect: Rect.parse(json['rect']),
      type: NodeType.workspace,
      num: asInt(json['num'], -1),
      visible: asBool(json['visible']),
      focused: asBool(json['focused']),
      urgent: asBool(json['urgent']),
      output: asString(json['output']),
      border: BorderType.parse(json['border']),
      borderWidth: asInt(json['current_border_width']),
      layout: ContainerLayout.parse(json['layout']),
      orientation: asString(json['orientation'], 'none'),
      windowRect: Rect.parse(json['window_rect']),
      decoRect: Rect.parse(json['deco_rect']),
      geometry: Rect.parse(json['geometry']),
      floatingNodes: BaseNode.parseChildren(json, 'floating_nodes'),
      nodes: BaseNode.parseChildren(json, 'nodes'),
    );
  }

  /// Whether this workspace has a number assigned to it.
  bool get hasNumber => num >= 0;

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

  /// The id of the window in this container, if it holds one.
  final int? window;

  /// Whether this container is marked as urgent.
  final bool urgent;

  /// The list of floating child nodes.
  @override
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

  /// The shell that this container is running in, always `miracle-wm`.
  final String shell;

  /// Whether this container inhibits idle.
  final bool inhibitIdle;

  /// Information about idle inhibitors.
  final IdleInhibitors? idleInhibitors;

  /// Additional window properties.
  final WindowProperties windowProperties;

  /// The list of child container nodes.
  @override
  final List<BaseNode> nodes;

  /// The scratchpad state, if this container reported one.
  final ScratchpadState? scratchpadState;

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
    return ContainerNode(
      id: asInt(json['id']),
      name: asString(json['name']),
      rect: Rect.parse(json['rect']),
      type: NodeType.fromString(asString(json['type'], 'con')) ??
          NodeType.container,
      focused: asBool(json['focused']),
      focus: asList(json['focus']).map(asInt).toList(growable: false),
      border: BorderType.parse(json['border']),
      borderWidth: asInt(json['current_border_width']),
      layout: ContainerLayout.parse(json['layout']),
      orientation: asString(json['orientation'], 'none'),
      percent: asDoubleOrNull(json['percent']),
      windowRect: Rect.parse(json['window_rect']),
      decoRect: Rect.parse(json['deco_rect']),
      geometry: Rect.parse(json['geometry']),
      window: asIntOrNull(json['window']),
      urgent: asBool(json['urgent']),
      floatingNodes: BaseNode.parseChildren(json, 'floating_nodes'),
      sticky: asBool(json['sticky']),
      fullscreenMode: asInt(json['fullscreen_mode']),
      pid: asIntOrNull(json['pid']),
      appId: asStringOrNull(json['app_id']),
      visible: asBool(json['visible']),
      shell: asString(json['shell'], 'miracle-wm'),
      inhibitIdle: asBool(json['inhibit_idle']),
      idleInhibitors: IdleInhibitors.parseOrNull(json['idle_inhibitors']),
      windowProperties: WindowProperties.parse(json['window_properties']),
      nodes: BaseNode.parseChildren(json, 'nodes'),
      scratchpadState: ScratchpadState.parseOrNull(json['scratchpad_state']),
    );
  }

  /// Whether this container holds an actual window rather than grouping others.
  bool get isWindow => window != null;

  /// Whether this container is floating rather than tiled.
  bool get isFloating => type == NodeType.floatingContainer;

  /// Whether this container is fullscreen on its output.
  bool get isFullscreen => fullscreenMode != 0;

  /// Whether this container is currently stashed on the scratchpad.
  bool get isOnScratchpad =>
      scratchpadState != null && scratchpadState != ScratchpadState.none;

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

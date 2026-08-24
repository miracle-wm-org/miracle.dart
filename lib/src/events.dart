import 'dart:convert';

import 'ipc_type.dart';
import 'json.dart';
import 'miracle_ipc.dart';
import 'nodes.dart';

/// An event pushed by miracle to a subscribed client.
///
/// Every event is one of the subclasses below, which makes it exhaustively
/// switchable:
///
/// ```dart
/// await for (final event in connection) {
///   switch (event) {
///     case WorkspaceEvent(:final change, :final current):
///       print('workspace ${current?.name} ${change.name}');
///     case WindowEvent(:final change, :final container):
///       print('window ${container.appId} ${change.name}');
///     default:
///       break;
///   }
/// }
/// ```
///
/// See also:
/// * [MiracleConnection.subscribe], to start receiving events
sealed class Event {
  Event({required this.type, this.raw});

  /// The IPC type that carried this event.
  final IpcType type;

  /// The decoded payload exactly as it was received.
  ///
  /// Use this to reach a field that this package does not model yet.
  final Object? raw;

  /// Parses [json] as the event carried by [type].
  ///
  /// An event type that this package does not model yet is returned as an
  /// [UnknownEvent] rather than throwing, so that a newer miracle can never
  /// tear down an event stream.
  factory Event.fromJson(IpcType type, Object? json) {
    switch (type) {
      case IpcType.ipcEventWorkspace:
        return WorkspaceEvent.fromJson(asObject(json));
      case IpcType.ipcEventOutput:
        return OutputEvent.fromJson(asObject(json));
      case IpcType.ipcEventMode:
        return ModeEvent.fromJson(asObject(json));
      case IpcType.ipcEventWindow:
        return WindowEvent.fromJson(asObject(json));
      case IpcType.ipcEventBinding:
        return BindingEvent.fromJson(asObject(json));
      case IpcType.ipcEventShutdown:
        return ShutdownEvent.fromJson(asObject(json));
      case IpcType.ipcEventTick:
        return TickEvent.fromJson(asObject(json));
      case IpcType.ipcEventConfigErrors:
        return ConfigErrorsEvent.fromJson(asList(json));
      case IpcType.ipcEventPlugin:
        return PluginEvent.fromJson(asObject(json));
      default:
        return UnknownEvent(type: type, raw: json);
    }
  }

  @override
  String toString() {
    return 'Event(type: $type)';
  }
}

/// The kind of change carried by a [WorkspaceEvent].
enum WorkspaceChange {
  /// The workspace was created.
  init('init'),

  /// The workspace is empty and is being destroyed since it is not visible.
  empty('empty'),

  /// The workspace was focused.
  ///
  /// See [WorkspaceEvent.old] for the workspace being switched away from.
  focus('focus'),

  /// The workspace was moved to a different output.
  move('move'),

  /// The workspace was renamed.
  rename('rename'),

  /// The configuration file has been reloaded.
  ///
  /// [WorkspaceEvent.current] is `null` for this change.
  reload('reload'),

  /// A change that this package does not model yet.
  ///
  /// Inspect [Event.raw] to see what miracle actually sent.
  unknown('');

  const WorkspaceChange(this.wireName);

  /// The name used on the wire.
  final String wireName;

  /// The change named [value], or [WorkspaceChange.unknown].
  factory WorkspaceChange.fromString(String value) {
    for (final change in WorkspaceChange.values) {
      if (change.wireName == value) return change;
    }
    return WorkspaceChange.unknown;
  }
}

/// The kind of change carried by a [WorkspaceEvent].
@Deprecated('Renamed to WorkspaceChange.')
typedef WorkspaceEventType = WorkspaceChange;

/// Sent whenever an event involving a workspace occurs, such as creation,
/// focusing or removal.
///
/// Subscribe with [SubscriptionType.workspace].
class WorkspaceEvent extends Event {
  /// What happened to the workspace.
  final WorkspaceChange change;

  /// The workspace being switched away from on a [WorkspaceChange.focus].
  ///
  /// `null` for every other change.
  final WorkspaceNode? old;

  /// The workspace the change applies to.
  ///
  /// `null` on a [WorkspaceChange.reload], which carries no workspace.
  final WorkspaceNode? current;

  WorkspaceEvent({
    required this.change,
    required this.old,
    required this.current,
    super.raw,
  }) : super(type: IpcType.ipcEventWorkspace);

  factory WorkspaceEvent.fromJson(Map<String, dynamic> json) {
    final old = asObjectOrNull(json['old']);
    final current = asObjectOrNull(json['current']);
    return WorkspaceEvent(
      change: WorkspaceChange.fromString(asString(json['change'])),
      old: old == null ? null : WorkspaceNode.fromJson(old),
      current: current == null ? null : WorkspaceNode.fromJson(current),
      raw: json,
    );
  }

  /// What happened to the workspace.
  @Deprecated('Renamed to WorkspaceEvent.change.')
  WorkspaceChange get workspaceEventType => change;

  @override
  String toString() =>
      'WorkspaceEvent(change: ${change.name}, old: ${old?.name}, '
      'current: ${current?.name})';
}

/// Sent whenever an event involving a workspace occurs.
@Deprecated('Renamed to WorkspaceEvent.')
typedef EventWorkspace = WorkspaceEvent;

/// The kind of change carried by an [OutputEvent].
enum OutputChange {
  /// The only change miracle reports: some output was added, removed or
  /// updated. Call [MiracleConnection.getOutputs] to see what changed.
  unspecified('unspecified'),

  /// A change that this package does not model yet.
  unknown('');

  const OutputChange(this.wireName);

  /// The name used on the wire.
  final String wireName;

  /// The change named [value], or [OutputChange.unknown].
  factory OutputChange.fromString(String value) {
    for (final change in OutputChange.values) {
      if (change.wireName == value) return change;
    }
    return OutputChange.unknown;
  }
}

/// Sent when outputs are updated.
///
/// miracle does not say which output changed or how, so a client that cares
/// should call [MiracleConnection.getOutputs] in response.
///
/// Subscribe with [SubscriptionType.output].
class OutputEvent extends Event {
  /// What happened, which is always [OutputChange.unspecified].
  final OutputChange change;

  OutputEvent({required this.change, super.raw})
      : super(type: IpcType.ipcEventOutput);

  factory OutputEvent.fromJson(Map<String, dynamic> json) => OutputEvent(
        change: OutputChange.fromString(asString(json['change'])),
        raw: json,
      );

  @override
  String toString() => 'OutputEvent(change: ${change.name})';
}

/// Sent when the current binding mode of the compositor changes.
///
/// Subscribe with [SubscriptionType.mode].
///
/// See also:
/// * [MiracleConnection.getBindingModes], for the list of possible modes
class ModeEvent extends Event {
  /// The name of the mode that is now active.
  ///
  /// This is one of the modes listed by
  /// [MiracleConnection.getBindingModes]: `default`, `resize`, `dragging`,
  /// `moving` or `overview`.
  final String mode;

  /// Whether the mode name contains pango markup, which is always `true`.
  final bool pangoMarkup;

  ModeEvent({required this.mode, required this.pangoMarkup, super.raw})
      : super(type: IpcType.ipcEventMode);

  factory ModeEvent.fromJson(Map<String, dynamic> json) => ModeEvent(
        mode: asString(json['change']),
        pangoMarkup: asBool(json['pango_markup'], true),
        raw: json,
      );

  /// The name of the mode that is now active.
  String get change => mode;

  /// Whether the default binding mode is active.
  bool get isDefault => mode == 'default';

  @override
  String toString() => 'ModeEvent(mode: "$mode")';
}

/// The kind of change carried by a [WindowEvent].
enum WindowChange {
  /// The window was created.
  created('new'),

  /// The window was closed.
  closed('close'),

  /// The window was focused.
  focused('focus'),

  /// The window's fullscreen mode has changed.
  fullscreenMode('fullscreen_mode'),

  /// The window has been reparented in the tree.
  moved('move'),

  /// The window was floated or unfloated.
  floating('floating'),

  /// A mark has been added to or removed from the window.
  marked('mark'),

  /// A change that this package does not model yet.
  unknown('');

  const WindowChange(this.wireName);

  /// The name used on the wire, e.g. `fullscreen_mode`.
  final String wireName;

  /// The change named [value], or [WindowChange.unknown].
  factory WindowChange.fromString(String value) {
    for (final change in WindowChange.values) {
      if (change.wireName == value) return change;
    }
    return WindowChange.unknown;
  }
}

/// Sent whenever an event involving a window occurs, such as opening,
/// focusing or closing.
///
/// Subscribe with [SubscriptionType.window].
class WindowEvent extends Event {
  /// What happened to the window.
  final WindowChange change;

  /// The container for the window the change applies to.
  final ContainerNode container;

  WindowEvent({required this.change, required this.container, super.raw})
      : super(type: IpcType.ipcEventWindow);

  factory WindowEvent.fromJson(Map<String, dynamic> json) => WindowEvent(
        change: WindowChange.fromString(asString(json['change'])),
        container: ContainerNode.fromJson(asObject(json['container'])),
        raw: json,
      );

  @override
  String toString() => 'WindowEvent(change: ${change.name}, '
      'container: ${container.appId ?? container.name} (${container.id}))';
}

/// The device that triggered a binding.
enum BindingInputType {
  keyboard('keyboard'),
  mouse('mouse'),

  /// An input type that this package does not model yet.
  unknown('');

  const BindingInputType(this.wireName);

  /// The name used on the wire.
  final String wireName;

  /// The input type named [value], or [BindingInputType.unknown].
  factory BindingInputType.fromString(String value) {
    for (final type in BindingInputType.values) {
      if (type.wireName == value) return type;
    }
    return BindingInputType.unknown;
  }
}

/// The binding that was triggered, as reported by a [BindingEvent].
class BindingInfo {
  /// The command that was run.
  final String command;

  /// The modifiers that were held, e.g. `meta`, `shift` or `ctrl`.
  final List<String> eventStateMask;

  /// The xkb keysym of the key that was pressed.
  final int inputCode;

  /// The stringified keysym, if miracle could produce one.
  final String? symbol;

  /// The device that triggered the binding.
  final BindingInputType inputType;

  BindingInfo({
    required this.command,
    required this.eventStateMask,
    required this.inputCode,
    required this.symbol,
    required this.inputType,
  });

  factory BindingInfo.fromJson(Map<String, dynamic> json) => BindingInfo(
        command: asString(json['command']),
        eventStateMask: asStringList(json['event_state_mask']),
        inputCode: asInt(json['input_code']),
        symbol: asStringOrNull(json['symbol']),
        // The wiki documents `input_type`; miracle emits `type`.
        inputType: BindingInputType.fromString(
          asString(json['input_type'] ?? json['type']),
        ),
      );

  /// Whether [modifier] was held when the binding fired.
  bool hasModifier(String modifier) => eventStateMask.contains(modifier);

  @override
  String toString() => 'BindingInfo(command: "$command", '
      'modifiers: $eventStateMask, symbol: $symbol, '
      'inputType: ${inputType.name})';
}

/// Sent whenever a binding is triggered in response to keyboard or mouse input.
///
/// Subscribe with [SubscriptionType.binding].
class BindingEvent extends Event {
  /// The binding that was triggered.
  final BindingInfo binding;

  BindingEvent({required this.binding, super.raw})
      : super(type: IpcType.ipcEventBinding);

  factory BindingEvent.fromJson(Map<String, dynamic> json) => BindingEvent(
        binding: BindingInfo.fromJson(asObject(json['binding'])),
        raw: json,
      );

  /// What happened, which is always `run`.
  String get change => 'run';

  @override
  String toString() => 'BindingEvent(binding: $binding)';
}

/// Why miracle is shutting down.
enum ShutdownChange {
  /// miracle is restarting.
  restart('restart'),

  /// miracle is exiting.
  exit('exit'),

  /// A reason that this package does not model yet.
  unknown('');

  const ShutdownChange(this.wireName);

  /// The name used on the wire.
  final String wireName;

  /// The change named [value], or [ShutdownChange.unknown].
  factory ShutdownChange.fromString(String value) {
    for (final change in ShutdownChange.values) {
      if (change.wireName == value) return change;
    }
    return ShutdownChange.unknown;
  }
}

/// Sent right before miracle shuts down.
///
/// Subscribe with [SubscriptionType.shutdown].
class ShutdownEvent extends Event {
  /// Why miracle is shutting down.
  final ShutdownChange change;

  ShutdownEvent({required this.change, super.raw})
      : super(type: IpcType.ipcEventShutdown);

  factory ShutdownEvent.fromJson(Map<String, dynamic> json) => ShutdownEvent(
        change: ShutdownChange.fromString(asString(json['change'])),
        raw: json,
      );

  @override
  String toString() => 'ShutdownEvent(change: ${change.name})';
}

/// Sent when an IPC client sends a `SEND_TICK` message.
///
/// Subscribe with [SubscriptionType.tick]. Subscribing immediately delivers
/// one event with [first] set to `true`, which is a convenient way to know
/// that every event sent before the subscription has been drained.
class TickEvent extends Event {
  /// Whether this event was triggered by subscribing to tick events.
  final bool first;

  /// The payload that was provided to [MiracleConnection.sendTick].
  ///
  /// This is an empty string when no payload was provided.
  final String payload;

  TickEvent({required this.first, required this.payload, super.raw})
      : super(type: IpcType.ipcEventTick);

  factory TickEvent.fromJson(Map<String, dynamic> json) => TickEvent(
        first: asBool(json['first']),
        payload: asString(json['payload']),
        raw: json,
      );

  /// The payload decoded as JSON, or `null` if it is empty or not JSON.
  Object? get jsonPayload {
    if (payload.isEmpty) return null;
    try {
      return jsonDecode(payload);
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() => 'TickEvent(first: $first, payload: "$payload")';
}

/// How severe a [ConfigError] is.
enum ConfigErrorLevel {
  warning('warning'),
  error('error'),

  /// A level that this package does not model yet.
  unknown('');

  const ConfigErrorLevel(this.wireName);

  /// The name used on the wire.
  final String wireName;

  /// The level named [value], or [ConfigErrorLevel.unknown].
  factory ConfigErrorLevel.fromString(String value) {
    for (final level in ConfigErrorLevel.values) {
      if (level.wireName == value) return level;
    }
    return ConfigErrorLevel.unknown;
  }
}

/// A single problem found while loading the configuration.
class ConfigError {
  /// The path to the configuration file the error came from.
  final String filename;

  /// The 1-based line number of the error.
  final int line;

  /// The 1-based column number of the error.
  final int column;

  /// How severe the problem is.
  final ConfigErrorLevel level;

  /// A human-readable description of the problem.
  final String message;

  ConfigError({
    required this.filename,
    required this.line,
    required this.column,
    required this.level,
    required this.message,
  });

  factory ConfigError.fromJson(Map<String, dynamic> json) => ConfigError(
        filename: asString(json['filename']),
        line: asInt(json['line']),
        column: asInt(json['column']),
        level: ConfigErrorLevel.fromString(asString(json['level'])),
        message: asString(json['message']),
      );

  @override
  String toString() => '$filename:$line:$column: ${level.name}: $message';
}

/// Sent when miracle (re)loads its configuration and collects parse errors.
///
/// Subscribe with [SubscriptionType.configErrors]. Subscribing immediately
/// delivers one event carrying the errors of the most recent load, which is
/// an empty list when there were none.
class ConfigErrorsEvent extends Event {
  /// Every problem found during the most recent configuration load.
  final List<ConfigError> errors;

  ConfigErrorsEvent({required this.errors, super.raw})
      : super(type: IpcType.ipcEventConfigErrors);

  factory ConfigErrorsEvent.fromJson(List<dynamic> json) => ConfigErrorsEvent(
        errors: asObjectList(json)
            .map(ConfigError.fromJson)
            .toList(growable: false),
        raw: json,
      );

  /// Whether the configuration loaded with any problems at all.
  bool get hasProblems => errors.isNotEmpty;

  /// Only the problems reported as errors.
  Iterable<ConfigError> get onlyErrors =>
      errors.where((error) => error.level == ConfigErrorLevel.error);

  /// Only the problems reported as warnings.
  Iterable<ConfigError> get onlyWarnings =>
      errors.where((error) => error.level == ConfigErrorLevel.warning);

  @override
  String toString() => 'ConfigErrorsEvent(errors: ${errors.length})';
}

/// Sent when a loaded plugin publishes an event on its namespace.
///
/// Unlike other events, plugin events are subscribed to per namespace.
///
/// See also:
/// * [MiracleConnection.subscribeToPlugin], to subscribe to a namespace
/// * [MiracleConnection.pluginEventsFor], to listen to one namespace
/// * [MiracleConnection.pluginCommand], to send a command to a plugin
class PluginEvent extends Event {
  /// The namespace of the plugin that published the event.
  final String plugin;

  /// The arbitrary JSON payload published by the plugin.
  ///
  /// This is the raw string when the plugin published something that is not
  /// valid JSON.
  final Object? payload;

  PluginEvent({required this.plugin, required this.payload, super.raw})
      : super(type: IpcType.ipcEventPlugin);

  factory PluginEvent.fromJson(Map<String, dynamic> json) => PluginEvent(
        plugin: asString(json['plugin']),
        payload: json['payload'],
        raw: json,
      );

  /// The payload as a JSON object, or `null` if it is not one.
  Map<String, dynamic>? get payloadObject => asObjectOrNull(payload);

  @override
  String toString() => 'PluginEvent(plugin: "$plugin", payload: $payload)';
}

/// An event that this package does not model.
///
/// miracle accepts subscriptions to `input` without emitting anything yet,
/// and reserves the bar-related event types that it will never send. Those,
/// plus anything a newer miracle adds, surface here so that the event stream
/// keeps flowing.
class UnknownEvent extends Event {
  UnknownEvent({required super.type, super.raw});

  @override
  String toString() => 'UnknownEvent(type: $type, raw: $raw)';
}

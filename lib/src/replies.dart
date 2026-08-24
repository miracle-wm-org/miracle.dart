import 'events.dart';
import 'geometry.dart';
import 'json.dart';
import 'miracle_ipc.dart';
import 'nodes.dart';

/// Created in response to a [MiracleConnection.command] call.
///
/// One result is produced for every command in the payload, in order, so
/// `resize grow width 10; meow 5` produces two results.
///
/// See also:
/// * [MiracleConnection.command], to send a command
class CommandResult {
  /// `true` if the command was issued, otherwise `false`.
  final bool success;

  /// `true` if the command failed at parse time.
  ///
  /// This is most often caused by an unknown command. It is always `false`
  /// when [success] is `true`.
  final bool parseError;

  /// A human-readable error message, if any.
  ///
  /// This is always `null` when [success] is `true`.
  final String? error;

  CommandResult({
    required this.success,
    this.parseError = false,
    this.error,
  });

  factory CommandResult.fromJson(Map<String, dynamic> json) => CommandResult(
        success: asBool(json['success']),
        parseError: asBool(json['parse_error']),
        error: asStringOrNull(json['error']),
      );

  @override
  String toString() => success
      ? 'CommandResult(success: true)'
      : 'CommandResult(success: false, parseError: $parseError, error: $error)';
}

/// Thrown when a command sent to miracle failed.
///
/// See also:
/// * [MiracleConnection.run], which throws this on failure
class MiracleCommandException implements Exception {
  /// The command that was sent.
  final String command;

  /// The results reported by miracle, in order.
  final List<CommandResult> results;

  MiracleCommandException(this.command, this.results);

  /// The results that failed.
  Iterable<CommandResult> get failures =>
      results.where((result) => !result.success);

  @override
  String toString() {
    final reasons = failures
        .map((failure) => failure.error ?? 'unknown error')
        .join('; ');
    return 'MiracleCommandException: "$command" failed: $reasons';
  }
}

/// Created in response to a [MiracleConnection.subscribe] call.
///
/// See also:
/// * [MiracleConnection.subscribe], to subscribe to an event
class SubscribeResult {
  /// `true` if every requested subscription was registered.
  final bool success;

  /// A human-readable error message, if any.
  final String? error;

  SubscribeResult({required this.success, this.error});

  factory SubscribeResult.fromJson(Map<String, dynamic> json) =>
      SubscribeResult(
        success: asBool(json['success']),
        error: asStringOrNull(json['error']),
      );

  @override
  String toString() => 'SubscribeResult(success: $success, error: $error)';
}

/// Created in response to the [MiracleConnection.getWorkspaces] call.
///
/// See also:
/// * [MiracleConnection.getWorkspaces], to list the available workspaces
class WorkspaceResult {
  /// The number of the workspace, or `-1` for workspaces without a number.
  final int? num;

  /// The name of the workspace, if any.
  final String? name;

  /// `true` if the workspace is visible, otherwise `false`.
  final bool visible;

  /// `true` if the workspace is focused, otherwise `false`.
  final bool focused;

  /// `true` if the workspace is urgent, otherwise `false`.
  ///
  /// Legacy, and always `false`.
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
      num: asIntOrNull(json['num']),
      name: asStringOrNull(json['name']),
      visible: asBool(json['visible']),
      focused: asBool(json['focused']),
      urgent: asBool(json['urgent']),
      output: asString(json['output']),
      rect: Rect.parse(json['rect']),
    );
  }

  @override
  String toString() => 'WorkspaceResult(num: $num, name: "$name", '
      'visible: $visible, focused: $focused, output: "$output", rect: $rect)';
}

/// Created in response to a [MiracleConnection.getOutputs] call.
///
/// This is the flat view of an output. The same output appears in the tree as
/// an [OutputNode], which additionally carries its workspaces.
///
/// See also:
/// * [MiracleConnection.getOutputs], to list the available outputs
class OutputResult {
  /// The name of the output, e.g. `HDMI-A-2`.
  final String name;

  /// The make of the output.
  final String make;

  /// The model of the output.
  final String model;

  /// The serial number of the output, as a hexadecimal string.
  final String serial;

  /// Whether this output is used.
  final bool active;

  /// Whether the output is on.
  ///
  /// Deprecated in favour of [power], which carries the same value.
  final bool dpms;

  /// Whether the output is on.
  final bool power;

  /// Whether this output is the primary output.
  final bool primary;

  /// The scale of the output, or `-1` if it is not used.
  final double scale;

  /// The subpixel hinting in use on the output, if it reported one.
  final SubpixelHinting? subpixelHinting;

  /// The transform of the output, if it reported one.
  final OutputTransform? transform;

  /// The name of the current workspace, or `null` for disabled outputs.
  final String? currentWorkspace;

  /// The modes supported by this output.
  final List<OutputMode> modes;

  /// The current mode of the output, if it reported one.
  final OutputMode? currentMode;

  /// The bounds of the output, if it reported them.
  final Rect? rect;

  OutputResult({
    required this.name,
    required this.make,
    required this.model,
    required this.serial,
    required this.active,
    required this.dpms,
    required this.power,
    required this.primary,
    required this.scale,
    required this.subpixelHinting,
    required this.transform,
    required this.currentWorkspace,
    required this.modes,
    required this.currentMode,
    required this.rect,
  });

  factory OutputResult.fromJson(Map<String, dynamic> json) {
    final dpms = asBool(json['dpms']);
    return OutputResult(
      name: asString(json['name']),
      make: asString(json['make'], 'Unknown'),
      model: asString(json['model'], 'Unknown'),
      serial: asString(json['serial'], 'Unknown'),
      active: asBool(json['active']),
      dpms: dpms,
      power: asBool(json['power'], dpms),
      primary: asBool(json['primary']),
      scale: asDouble(json['scale'], -1),
      subpixelHinting: SubpixelHinting.parseOrNull(json['subpixel_hinting']),
      transform: OutputTransform.parseOrNull(json['transform']),
      currentWorkspace: asStringOrNull(json['current_workspace']),
      modes: OutputMode.parseList(json['modes']),
      currentMode: OutputMode.parseOrNull(json['current_mode']),
      rect: Rect.parseOrNull(json['rect']),
    );
  }

  @override
  String toString() => 'OutputResult(name: "$name", make: "$make", '
      'model: "$model", active: $active, primary: $primary, scale: $scale, '
      'currentWorkspace: $currentWorkspace, currentMode: $currentMode)';
}

/// Created in response to a [MiracleConnection.getMarks] call.
///
/// See also:
/// * [MiracleConnection.getMarks], to get the currently set marks
class MarksResult {
  /// The list of marks currently set.
  ///
  /// A mark may be applied to more than one container, but appears once here.
  final List<String> marks;

  MarksResult({required this.marks});

  factory MarksResult.fromJson(List<dynamic> json) {
    return MarksResult(marks: asStringList(json));
  }

  @override
  String toString() => 'MarksResult(marks: $marks)';
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

  VersionResult({
    required this.major,
    required this.minor,
    required this.patch,
    required this.humanReadable,
    required this.loadedConfigFilename,
  });

  factory VersionResult.fromJson(Map<String, dynamic> json) {
    return VersionResult(
      major: asInt(json['major']),
      minor: asInt(json['minor']),
      patch: asInt(json['patch']),
      humanReadable: asString(json['human_readable']),
      loadedConfigFilename: asString(json['loaded_config_file_name']),
    );
  }

  /// Whether the running version is at least [major].[minor].[patch].
  bool isAtLeast(int major, [int minor = 0, int patch = 0]) {
    if (this.major != major) return this.major > major;
    if (this.minor != minor) return this.minor > minor;
    return this.patch >= patch;
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
  ///
  /// `default` is always present.
  final List<String> modes;

  BindingModesResult({required this.modes});

  factory BindingModesResult.fromJson(List<dynamic> json) {
    return BindingModesResult(modes: asStringList(json));
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
  /// This will be a mode found in [BindingModesResult].
  ///
  /// Use [MiracleConnection.getBindingModes] to list the available modes.
  final String name;

  BindingStateResult({required this.name});

  factory BindingStateResult.fromJson(Map<String, dynamic> json) {
    return BindingStateResult(name: asString(json['name']));
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
    return TickResult(success: asBool(json['success']));
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
    return SyncResult(name: asString(json['name']));
  }

  @override
  String toString() {
    return 'SyncResponse(name: "$name")';
  }
}

/// Created in response to a [MiracleConnection.pluginCommand] call.
///
/// See also:
/// * [MiracleConnection.pluginCommand], to route a command to a plugin
/// * [PluginEvent], which a plugin uses to push data back to clients
class PluginCommandResult {
  /// Whether the plugin handled the command.
  ///
  /// This is `false` when no plugin owns the requested namespace, when the
  /// owning plugin does not implement a command handler, or when the
  /// request/response was not valid JSON.
  final bool success;

  /// The plugin's JSON response, present when [success] is `true`.
  final Object? response;

  /// A human-readable error message, present when [success] is `false`.
  final String? error;

  PluginCommandResult({
    required this.success,
    this.response,
    this.error,
  });

  factory PluginCommandResult.fromJson(Map<String, dynamic> json) =>
      PluginCommandResult(
        success: asBool(json['success']),
        response: json['response'],
        error: asStringOrNull(json['error']),
      );

  /// The response decoded as a JSON object, or `null` if it is not one.
  Map<String, dynamic>? get responseObject => asObjectOrNull(response);

  @override
  String toString() => success
      ? 'PluginCommandResult(success: true, response: $response)'
      : 'PluginCommandResult(success: false, error: $error)';
}

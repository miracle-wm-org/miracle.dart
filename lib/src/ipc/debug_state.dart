import 'commands.dart';
import 'geometry.dart';
import 'json.dart';
import 'miracle_ipc.dart';

/// Created in response to a [MiracleConnection.getDebugState] call.
///
/// This is a snapshot of the information that powers the bundled debug
/// overlay: where the cursor is, what is underneath it, and every window
/// across every output and workspace.
///
/// Introduced in miracle v0.10.0.
///
/// See also:
/// * [MiracleConnection.getDebugState], to request a snapshot
/// * [MiracleCommand.debugOverlay], to toggle the bundled overlay
class DebugState {
  /// The current cursor position, in global output coordinates.
  final Position cursor;

  /// The [DebugWindow.debugId] of the window under the cursor, if any.
  final int? windowUnderCursor;

  /// Every window, regardless of which workspace or output it is on.
  final List<DebugWindow> windows;

  DebugState({
    required this.cursor,
    required this.windowUnderCursor,
    required this.windows,
  });

  factory DebugState.fromJson(Map<String, dynamic> json) {
    final underCursor = asIntOrNull(json['window_under_cursor']);
    return DebugState(
      cursor: Position.parse(json['cursor']),
      // miracle reports -1 when the cursor is not over a window.
      windowUnderCursor:
          underCursor == null || underCursor < 0 ? null : underCursor,
      windows: asObjectList(json['windows'])
          .map(DebugWindow.fromJson)
          .toList(growable: false),
    );
  }

  /// The window under the cursor, or `null` when there is none.
  DebugWindow? get windowUnderCursorInfo {
    final id = windowUnderCursor;
    if (id == null) return null;
    for (final window in windows) {
      if (window.debugId == id) return window;
    }
    return null;
  }

  /// Every window on the output named [output].
  Iterable<DebugWindow> windowsOnOutput(String output) =>
      windows.where((window) => window.output == output);

  @override
  String toString() => 'DebugState(cursor: $cursor, '
      'windowUnderCursor: $windowUnderCursor, windows: ${windows.length})';
}

/// A single window in a [DebugState] snapshot.
class DebugWindow {
  /// A stable container id used by the debug tooling.
  ///
  /// This matches [DebugState.windowUnderCursor].
  final int debugId;

  /// The window's logical position and size, in global output coordinates.
  final Rect rect;

  /// The visible (clip) area, expressed relative to [rect].
  final Rect windowRect;

  /// The global bounding box of the surface's input area, if reported.
  final Rect? inputBounds;

  /// The rectangles that accept pointer input, in global coordinates.
  ///
  /// An empty list means the whole surface accepts input, which is to say
  /// that it is equal to [inputBounds].
  final List<Rect> inputRegion;

  /// The surface content size, if reported.
  ///
  /// This is what the client has actually been configured to, which is
  /// distinct from the logical [rect].
  final Size? contentSize;

  /// Whether the window is focused.
  final bool focused;

  /// Whether the window is currently visible.
  final bool visible;

  /// The application id of the window, if any.
  final String? appId;

  /// The name of the window, if any.
  final String? name;

  /// The name of the output the window is on.
  final String output;

  /// Whether that output is focused.
  final bool outputFocused;

  /// The id of the workspace the window is on.
  final int workspaceId;

  /// The name of that workspace, if it has one.
  final String? workspaceName;

  /// The entry exactly as it was received.
  ///
  /// Debug payloads carry the same per-window fields as `GET_TREE` plus
  /// whatever the current miracle release annotates them with; use this to
  /// reach a field this package does not model yet.
  final Map<String, dynamic> raw;

  DebugWindow({
    required this.debugId,
    required this.rect,
    required this.windowRect,
    required this.inputBounds,
    required this.inputRegion,
    required this.contentSize,
    required this.focused,
    required this.visible,
    required this.appId,
    required this.name,
    required this.output,
    required this.outputFocused,
    required this.workspaceId,
    required this.workspaceName,
    required this.raw,
  });

  factory DebugWindow.fromJson(Map<String, dynamic> json) => DebugWindow(
        debugId: asInt(json['debug_id']),
        rect: Rect.parse(json['rect']),
        windowRect: Rect.parse(json['window_rect']),
        inputBounds: Rect.parseOrNull(json['input_bounds']),
        inputRegion: asObjectList(json['input_region'])
            .map(Rect.fromJson)
            .toList(growable: false),
        contentSize: Size.parseOrNull(json['content_size']),
        focused: asBool(json['focused']),
        visible: asBool(json['visible']),
        appId: asStringOrNull(json['app_id']),
        name: asStringOrNull(json['name']),
        output: asString(json['output']),
        outputFocused: asBool(json['output_focused']),
        workspaceId: asInt(json['workspace_id']),
        workspaceName: asStringOrNull(json['workspace_name']),
        raw: json,
      );

  /// Whether the whole surface accepts pointer input.
  bool get acceptsInputEverywhere => inputRegion.isEmpty;

  @override
  String toString() => 'DebugWindow(debugId: $debugId, appId: $appId, '
      'output: "$output", workspace: $workspaceId, rect: $rect, '
      'focused: $focused, visible: $visible)';
}

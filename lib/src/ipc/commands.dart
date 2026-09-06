import 'miracle_ipc.dart';

/// A cardinal direction.
enum Direction {
  left,
  right,
  down,
  up;

  /// The name used on the wire.
  String get wireName => name;
}

/// The axis that [MiracleCommand.split] splits a container along.
enum SplitDirection {
  vertical,
  horizontal,

  /// Splits along the axis that is not currently in use.
  toggle;

  /// The name used on the wire.
  String get wireName => name;
}

/// A layout scheme that a container can be put into.
enum LayoutMode {
  /// The layout configured as the default, i.e. `layout default`.
  defaultLayout('default'),
  tabbed('tabbed'),
  stacking('stacking'),
  splitv('splitv'),
  splith('splith');

  const LayoutMode(this.wireName);

  /// The name used on the wire.
  final String wireName;
}

/// A relative container to focus.
enum FocusTarget {
  /// The parent of the current container.
  parent('parent'),

  /// The first child of the current container.
  child('child'),

  /// The first floating container.
  floating('floating'),

  /// The first tiling container.
  tiling('tiling'),

  /// A floating or tiling container, depending on what is selected.
  modeToggle('mode_toggle');

  const FocusTarget(this.wireName);

  /// The name used on the wire, e.g. `mode_toggle`.
  final String wireName;
}

/// An adjacent container to focus.
enum FocusSibling {
  next,
  prev;

  /// The name used on the wire.
  String get wireName => name;
}

/// A workspace to move a container to, relative to the current one.
enum RelativeWorkspace {
  prev,
  next,
  current;

  /// The name used on the wire.
  String get wireName => name;
}

/// A workspace to focus, relative to the currently focused one.
enum WorkspaceDirection {
  /// The numerically greater workspace after the focused one.
  next('next'),

  /// The numerically lesser workspace before the focused one.
  prev('prev'),

  /// Like [next], confined to the focused output.
  nextOnOutput('next_on_output'),

  /// Like [prev], confined to the focused output.
  prevOnOutput('prev_on_output');

  const WorkspaceDirection(this.wireName);

  /// The name used on the wire, e.g. `next_on_output`.
  final String wireName;
}

/// The unit a movement or resize amount is expressed in.
enum SizeUnit {
  /// Pixels.
  px('px'),

  /// Percentage points of the output.
  ppt('ppt');

  const SizeUnit(this.wireName);

  /// The name used on the wire.
  final String wireName;
}

/// Whether a resize grows or shrinks a container.
enum ResizeMode {
  grow,
  shrink;

  /// The name used on the wire.
  String get wireName => name;
}

/// The dimension a resize applies to.
enum ResizeAxis {
  width,
  height;

  /// The name used on the wire.
  String get wireName => name;
}

/// How a new mark interacts with the marks already on a container.
enum MarkMode {
  /// Add the mark in addition to existing marks.
  add('--add'),

  /// Remove all existing marks and replace them with this one.
  replace('--replace');

  const MarkMode(this.wireName);

  /// The option used on the wire.
  final String wireName;
}

/// A tri-state toggle used by commands such as `sticky`.
enum Toggle {
  enable,
  disable,
  toggle;

  /// The name used on the wire.
  String get wireName => name;
}

/// Which gaps a `gaps` command applies to.
enum GapKind {
  /// The space between two adjacent windows.
  inner('inner'),

  /// The space along every screen edge.
  outer('outer'),

  /// The space along the left and right screen edges.
  horizontal('horizontal'),

  /// The space along the top and bottom screen edges.
  vertical('vertical'),
  top('top'),
  right('right'),
  bottom('bottom'),
  left('left');

  const GapKind(this.wireName);

  /// The name used on the wire.
  final String wireName;
}

/// Which workspaces a `gaps` command applies to.
enum GapScope {
  /// Only the current workspace.
  current('current'),

  /// Every workspace.
  all('all');

  const GapScope(this.wireName);

  /// The name used on the wire.
  final String wireName;
}

/// How a `gaps` command changes the current gap size.
enum GapOperation {
  set('set'),
  plus('plus'),
  minus('minus');

  const GapOperation(this.wireName);

  /// The name used on the wire.
  final String wireName;
}

/// Selects the output that a `focus` or `move` command applies to.
///
/// ```dart
/// MiracleCommand.focusOutput(OutputSelector.direction(Direction.right));
/// MiracleCommand.moveToOutput(OutputSelector.named(['VGA-1', 'VGA-2']));
/// ```
class OutputSelector {
  const OutputSelector._(this._parts);

  final List<String> _parts;

  /// The output in the given direction.
  factory OutputSelector.direction(Direction direction) =>
      OutputSelector._([direction.wireName]);

  /// The currently focused output.
  factory OutputSelector.current() => const OutputSelector._(['current']);

  /// The primary output.
  factory OutputSelector.primary() => const OutputSelector._(['primary']);

  /// Any output that is not the primary one.
  factory OutputSelector.nonPrimary() => const OutputSelector._(['nonprimary']);

  /// The next output.
  factory OutputSelector.next() => const OutputSelector._(['next']);

  /// The named outputs, cycled through in order when more than one is given.
  factory OutputSelector.named(List<String> names) {
    if (names.isEmpty) {
      throw ArgumentError.value(names, 'names', 'must not be empty');
    }
    return OutputSelector._(names.map(quoteArgument).toList(growable: false));
  }

  @override
  String toString() => _parts.join(' ');
}

/// Selects the container(s) a command applies to.
///
/// Criteria map onto i3's `[key="value"]` syntax and are prepended to the
/// command they qualify:
///
/// ```dart
/// // [app_id="firefox"] focus
/// MiracleCommand.focusMatching(Criteria(appId: 'firefox'));
/// ```
///
/// See also:
/// * <https://wiki.miracle-wm.org/develop/ipc/commands/focus/>
class Criteria {
  /// Matches the Wayland application id of a window.
  final String? appId;

  /// Matches the X11 class of a window.
  final String? className;

  /// Matches the X11 instance of a window.
  final String? instance;

  /// Matches the title of a window.
  final String? title;

  /// Matches the process id of a window.
  final int? pid;

  /// Matches containers carrying this mark.
  final String? mark;

  /// Matches the container with this id.
  final int? containerId;

  /// Matches containers on this workspace.
  final String? workspace;

  /// Matches containers whose urgency is in this state, e.g. `latest`.
  ///
  /// miracle parses this criterion but never matches on it, so a command
  /// scoped by it selects nothing. Read the `urgent` flag off the tree and
  /// target the container by [containerId] instead.
  final String? urgent;

  /// Matches only floating containers.
  final bool floating;

  /// Matches only tiling containers.
  final bool tiling;

  /// Matches every container.
  final bool all;

  const Criteria({
    this.appId,
    this.className,
    this.instance,
    this.title,
    this.pid,
    this.mark,
    this.containerId,
    this.workspace,
    this.urgent,
    this.floating = false,
    this.tiling = false,
    this.all = false,
  });

  /// Whether any criterion was set.
  bool get isEmpty => _parts.isEmpty;

  List<String> get _parts => [
        if (appId != null) 'app_id=${quoteArgument(appId!, force: true)}',
        if (className != null) 'class=${quoteArgument(className!, force: true)}',
        if (instance != null) 'instance=${quoteArgument(instance!, force: true)}',
        if (title != null) 'title=${quoteArgument(title!, force: true)}',
        if (pid != null) 'pid=$pid',
        if (mark != null) 'con_mark=${quoteArgument(mark!, force: true)}',
        if (containerId != null) 'con_id=$containerId',
        if (workspace != null) 'workspace=${quoteArgument(workspace!, force: true)}',
        if (urgent != null) 'urgent=${quoteArgument(urgent!, force: true)}',
        if (floating) 'floating',
        if (tiling) 'tiling',
        if (all) 'all',
      ];

  @override
  String toString() => '[${_parts.join(' ')}]';
}

/// Quotes [value] for inclusion in a command string.
///
/// A value is quoted when it contains whitespace or a quote, or when [force]
/// is set, as criteria values always require quoting.
String quoteArgument(String value, {bool force = false}) {
  final needsQuotes = force ||
      value.isEmpty ||
      value.contains(RegExp(r'[\s";\[\]]'));
  if (!needsQuotes) return value;
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

/// A single command that can be sent to miracle.
///
/// Every command documented at
/// <https://wiki.miracle-wm.org/develop/ipc/commands/> has a named
/// constructor here, so that a typo becomes a compile error rather than a
/// `parse_error` at runtime:
///
/// ```dart
/// await connection.run(MiracleCommand.focusDirection(Direction.left));
/// await connection.runAll([
///   MiracleCommand.mark('swapee'),
///   MiracleCommand.focusDirection(Direction.left),
///   MiracleCommand.swapWithMark('swapee'),
/// ]);
/// ```
///
/// Anything this class does not cover can still be sent verbatim with
/// [MiracleCommand.raw] or [MiracleConnection.command].
class MiracleCommand {
  /// The command, without any criteria.
  final String command;

  /// The containers the command applies to, if it was scoped.
  final Criteria? criteria;

  const MiracleCommand._(this.command, {this.criteria});

  /// A command written out by hand.
  ///
  /// Use this to reach a command that this package does not model yet, such
  /// as `fullscreen`, `floating`, `border`, `reload`, `restart` or `exit`.
  const MiracleCommand.raw(this.command, {this.criteria});

  /// Executes [program], optionally without startup id notification.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/exec/>.
  factory MiracleCommand.exec(String program, {bool noStartupId = false}) =>
      MiracleCommand._(
          'exec ${noStartupId ? '--no-startup-id ' : ''}$program');

  /// Makes the current window a split container along [direction].
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/split/>.
  factory MiracleCommand.split(SplitDirection direction) =>
      MiracleCommand._('split ${direction.wireName}');

  /// Sets the layout of the selected container.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/layout/>.
  factory MiracleCommand.layout(LayoutMode mode) =>
      MiracleCommand._('layout ${mode.wireName}');

  /// Toggles between the horizontal and vertical split layouts.
  factory MiracleCommand.layoutToggleSplit() =>
      const MiracleCommand._('layout toggle split');

  /// Cycles through every layout.
  factory MiracleCommand.layoutToggleAll() =>
      const MiracleCommand._('layout toggle all');

  /// Cycles through the given [modes] in order.
  factory MiracleCommand.layoutToggleAmong(List<LayoutMode> modes) {
    if (modes.isEmpty) {
      throw ArgumentError.value(modes, 'modes', 'must not be empty');
    }
    return MiracleCommand._(
        'layout toggle ${modes.map((mode) => mode.wireName).join(' ')}');
  }

  /// Focuses the container in [direction].
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/focus/>.
  factory MiracleCommand.focusDirection(Direction direction) =>
      MiracleCommand._('focus ${direction.wireName}');

  /// Focuses the container matching [criteria].
  factory MiracleCommand.focusMatching(Criteria criteria) =>
      MiracleCommand._('focus', criteria: criteria);

  /// Focuses the workspace of the container matching [criteria].
  factory MiracleCommand.focusWorkspaceOf(Criteria criteria) =>
      MiracleCommand._('focus workspace', criteria: criteria);

  /// Focuses a container relative to the selected one.
  factory MiracleCommand.focusTarget(FocusTarget target) =>
      MiracleCommand._('focus ${target.wireName}');

  /// Focuses an adjacent container.
  ///
  /// When [includeNonLeaf] is set the exact sibling container is focused,
  /// including non-leaf containers such as split containers.
  factory MiracleCommand.focusSibling(
    FocusSibling sibling, {
    bool includeNonLeaf = false,
  }) =>
      MiracleCommand._(
          'focus ${sibling.wireName}${includeNonLeaf ? ' sibling' : ''}');

  /// Focuses an output.
  factory MiracleCommand.focusOutput(OutputSelector output) =>
      MiracleCommand._('focus output $output');

  /// Moves the selected container in [direction].
  ///
  /// [amount] and [unit] only apply to floating containers, and default to
  /// 10 pixels.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/move/>.
  factory MiracleCommand.move(
    Direction direction, {
    int? amount,
    SizeUnit unit = SizeUnit.px,
  }) {
    final suffix = amount == null ? '' : ' $amount ${unit.wireName}';
    return MiracleCommand._('move ${direction.wireName}$suffix');
  }

  /// Moves the selected container to the given coordinates.
  factory MiracleCommand.moveToPosition(
    int x,
    int y, {
    SizeUnit xUnit = SizeUnit.px,
    SizeUnit yUnit = SizeUnit.px,
  }) =>
      MiracleCommand._(
          'move position $x ${xUnit.wireName} $y ${yUnit.wireName}');

  /// Centers the selected container on its output.
  ///
  /// When [absolute] is set the container is centered across every output.
  factory MiracleCommand.moveToCenter({bool absolute = false}) =>
      MiracleCommand._('move ${absolute ? 'absolute ' : ''}position center');

  /// Moves the selected floating container to the cursor.
  factory MiracleCommand.moveToMouse() =>
      const MiracleCommand._('move position mouse');

  /// Moves the selected container to the container marked [mark].
  factory MiracleCommand.moveToMark(String mark) =>
      MiracleCommand._('move container to mark ${quoteArgument(mark)}');

  /// Moves the selected container to the workspace named [name].
  factory MiracleCommand.moveToWorkspace(
    String name, {
    bool noAutoBackAndForth = false,
  }) =>
      MiracleCommand._('move ${noAutoBackAndForth ? '--no-auto-back-and-forth '
          : ''}container to workspace ${quoteArgument(name)}');

  /// Moves the selected container to the workspace numbered [name].
  factory MiracleCommand.moveToWorkspaceNumber(
    String name, {
    bool noAutoBackAndForth = false,
  }) =>
      MiracleCommand._('move ${noAutoBackAndForth ? '--no-auto-back-and-forth '
          : ''}container to workspace number ${quoteArgument(name)}');

  /// Moves the selected container to a workspace relative to the current one.
  factory MiracleCommand.moveToRelativeWorkspace(RelativeWorkspace workspace) =>
      MiracleCommand._('move container to workspace ${workspace.wireName}');

  /// Moves the selected container to another output.
  factory MiracleCommand.moveToOutput(OutputSelector output) =>
      MiracleCommand._('move container to output $output');

  /// Moves the current workspace to another output.
  factory MiracleCommand.moveWorkspaceToOutput(OutputSelector output) =>
      MiracleCommand._('move workspace to output $output');

  /// Moves the selected container to the scratchpad.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/scratchpad/>.
  factory MiracleCommand.moveToScratchpad({Criteria? criteria}) =>
      MiracleCommand._('move scratchpad', criteria: criteria);

  /// Shows a container from the scratchpad, or hides it if it is shown.
  factory MiracleCommand.scratchpadShow({Criteria? criteria}) =>
      MiracleCommand._('scratchpad show', criteria: criteria);

  /// Marks the selected container as [identifier].
  ///
  /// [mode] controls whether the mark is added to or replaces the existing
  /// marks, and [toggle] removes the mark again if it is already set.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/mark/>.
  factory MiracleCommand.mark(
    String identifier, {
    MarkMode? mode,
    bool toggle = false,
    Criteria? criteria,
  }) {
    final options = [
      if (mode != null) mode.wireName,
      if (toggle) '--toggle',
    ].join(' ');
    return MiracleCommand._(
      'mark ${options.isEmpty ? '' : '$options '}${quoteArgument(identifier)}',
      criteria: criteria,
    );
  }

  /// Removes [identifier] from the selected containers.
  ///
  /// Passing no identifier removes every mark from them.
  factory MiracleCommand.unmark([String? identifier, Criteria? criteria]) =>
      MiracleCommand._(
        identifier == null ? 'unmark' : 'unmark ${quoteArgument(identifier)}',
        criteria: criteria,
      );

  /// Grows or shrinks the selected container.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/resize/>.
  factory MiracleCommand.resize(
    ResizeMode mode,
    ResizeAxis axis,
    int amount, {
    SizeUnit unit = SizeUnit.px,
  }) =>
      MiracleCommand._(
          'resize ${mode.wireName} ${axis.wireName} $amount ${unit.wireName}');

  /// Sets the dimensions of the selected container.
  factory MiracleCommand.resizeSet({
    required int width,
    required int height,
    SizeUnit widthUnit = SizeUnit.px,
    SizeUnit heightUnit = SizeUnit.px,
  }) =>
      MiracleCommand._('resize set $width ${widthUnit.wireName} '
          '$height ${heightUnit.wireName}');

  /// Swaps the selected container with the container marked [mark].
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/swap/>.
  factory MiracleCommand.swapWithMark(String mark, {Criteria? criteria}) =>
      MiracleCommand._('swap container with mark ${quoteArgument(mark)}',
          criteria: criteria);

  /// Swaps the selected container with the window whose app id is [id].
  factory MiracleCommand.swapWithId(String id, {Criteria? criteria}) =>
      MiracleCommand._('swap container with id ${quoteArgument(id)}',
          criteria: criteria);

  /// Makes the selected floating window stick to the glass.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/sticky/>.
  factory MiracleCommand.sticky(Toggle toggle, {Criteria? criteria}) =>
      MiracleCommand._('sticky ${toggle.wireName}', criteria: criteria);

  /// Focuses the workspace named [name], or renames the current one to it.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/workspace/>.
  factory MiracleCommand.workspace(
    String name, {
    bool noAutoBackAndForth = false,
  }) =>
      MiracleCommand._('workspace ${noAutoBackAndForth
          ? '--no-auto-back-and-forth '
          : ''}${quoteArgument(name)}');

  /// Focuses the workspace numbered [name].
  factory MiracleCommand.workspaceNumber(
    String name, {
    bool noAutoBackAndForth = false,
  }) =>
      MiracleCommand._('workspace ${noAutoBackAndForth
          ? '--no-auto-back-and-forth '
          : ''}number ${quoteArgument(name)}');

  /// Focuses a workspace relative to the focused one.
  factory MiracleCommand.workspaceDirection(WorkspaceDirection direction) =>
      MiracleCommand._('workspace ${direction.wireName}');

  /// Focuses the previously focused workspace.
  factory MiracleCommand.workspaceBackAndForth() =>
      const MiracleCommand._('workspace back_and_forth');

  /// Renames a workspace.
  ///
  /// Renames the selected workspace when [from] is omitted. A rename to a
  /// name or number that is already taken is ignored by miracle.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/rename/>.
  factory MiracleCommand.renameWorkspace({String? from, required String to}) =>
      MiracleCommand._('rename workspace '
          '${from == null ? '' : '${quoteArgument(from)} '}'
          'to ${quoteArgument(to)}');

  /// Changes the gaps globally or on the current workspace.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/gaps/>.
  factory MiracleCommand.gaps({
    required GapKind kind,
    required GapScope scope,
    required GapOperation operation,
    required int pixels,
  }) =>
      MiracleCommand._('gaps ${kind.wireName} ${scope.wireName} '
          '${operation.wireName} $pixels');

  /// Does nothing.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/nop/>.
  factory MiracleCommand.nop() => const MiracleCommand._('nop');

  /// Toggles, shows or hides the bundled debug overlay.
  ///
  /// See <https://wiki.miracle-wm.org/develop/ipc/commands/debug/>.
  factory MiracleCommand.debugOverlay([Toggle toggle = Toggle.toggle]) =>
      MiracleCommand._(switch (toggle) {
        Toggle.enable => 'debug overlay on',
        Toggle.disable => 'debug overlay off',
        Toggle.toggle => 'debug overlay toggle',
      });

  /// This command as miracle expects it on the wire.
  String toCommandString() {
    final scope = criteria;
    if (scope == null || scope.isEmpty) return command;
    return '$scope $command';
  }

  @override
  String toString() => toCommandString();
}

/// Joins [commands] into a single `RUN_COMMAND` payload.
///
/// miracle runs each command in order and replies with one result per
/// command.
String joinCommands(Iterable<MiracleCommand> commands) =>
    commands.map((command) => command.toCommandString()).join('; ');

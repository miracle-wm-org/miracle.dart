# Changelog

## 2.4.0

Adds support for miracle's per-workspace window placement policy. A workspace
either tiles the windows opened on it, which is the default, or floats them and
centres them over the workspace. The policy is set with the
`workspace [<num>|<name>] policy float|tile` command, documented at
<https://wiki.miracle-wm.org/develop/ipc/commands/workspace/>, and it is
reported by `GET_TREE` and `GET_WORKSPACES`. Changing it only affects windows
opened afterwards; the windows already on the workspace stay where they are.

### API additions

- `WindowPlacementPolicy`, with `tile` and `float`. A miracle that predates the
  policy omits the field and always tiles, so it reads as `tile` there.
- `WorkspaceNode.policy`, read from `GET_TREE` and printed by `toString`.
  Workspace events carry whole workspace nodes, so `current` and `old` report
  the policy too.
- `WorkspaceResult.policy`, read from `GET_WORKSPACES`.
- `MiracleCommand.workspacePolicy`, which targets the focused workspace by
  default or a workspace given by number or name.

## 2.3.0

Adds support for miracle's `GET_KEYBINDS` IPC message, documented at
<https://wiki.miracle-wm.org/develop/ipc/get_keybinds/>. It reports the
effective keybindings from the running compositor's configuration, so a bar or
a configuration tool can show what a key does right now without reparsing the
configuration file.

### API additions

- `MiracleConnection.getKeybinds`, returning a `KeybindsResult` with the
  resolved `primaryModifier` and every configured `Keybind`.
- `Keybind`, carrying the built-in `action` (plus the raw `actionName`, so an
  action miracle adds before this package knows about it stays visible), the
  shell `command`, the `keyboardAction`, the resolved `modifiers`, the
  `configuredModifiers` as written in the configuration file, and the keysym.
- `KeybindModifiers`, a typed `Modifier` list alongside the lossless
  `modifier_mask` int, with `has(Modifier)`.
- `IpcType.ipcGetKeybinds`, the wire type (202).

The reply reuses the configuration API's `Modifier`, `BuiltInKeyCommand` and
`KeyboardAction` enums, which already carry exactly these wire names.

## 2.2.0

Adds `MiracleConfig`, an API for reading and writing miracle's configuration
file. It rehomes the Dart FFI bindings from the
[miracle-settings](https://github.com/miracle-wm-org/miracle-settings)
repository, which has been archived.

The bindings are generated with `ffigen` from the C header that ships with
miracle-wm, and both the header and the generated code are checked in; CI
regenerates them and fails on drift.

### API additions

- `MiracleConfig`, loaded with `MiracleConfig.load(path)` or
  `MiracleConfig.loadDefault()`. Scalar settings — gaps, `terminal`,
  `resizeJump`, `primaryModifier`, `backgroundColor` and the rest — are plain
  getters and setters. `save()` writes back; `dispose()` frees the native
  configuration, with a `Finalizer` as a backstop.
- Grouped settings as live views: `border`, `mouse`, `touchpad`, `keymap`,
  `cursor`, `magnifier`, `dragAndDrop`, `outputFilter`, `hoverClick`,
  `simulatedSecondaryClick`, `slowKeys` and `stickyKeys`.
- Collections as write-through `List` views: `includes`, `plugins`,
  `startupApps`, `environmentVariables`, `workspaceConfigs`,
  `customKeyCommands`, `builtInKeyCommandOverrides` and `animateableEvents`.
- Enums covering the C library's option tables: `Modifier`, `MouseButton`,
  `PointerAction`, `KeyboardAction`, `BuiltInKeyCommand`, `AnimationType`,
  `EaseFunction`, `CursorFocusMode`, `Handedness`, `Acceleration`,
  `TouchpadClickMode` and `TouchpadScrollMode`. A test checks each against the
  live option tables, so an upstream renumbering cannot pass unnoticed.
- Value types `RgbaColor`, `StartupApp`, `EnvironmentVariable`,
  `WorkspaceConfig`, `Plugin`, `CustomKeyCommand`, `KeyCommandOverride`,
  `BuiltInAnimation`, `MiracleConfigError` and `MiracleConfigSaveResult`.
- `MiracleConfigException`, and `MiracleConfig.isAvailable` for checking
  without throwing. Importing `package:miracle` never loads the native library,
  so the IPC API is unaffected on systems without miracle-wm installed.

### Requirements

- The configuration API needs `libmiracle-wm-c`, installed by miracle-wm 0.10
  and newer. The IPC API has no new requirements.
- The package now depends on `package:ffi`, which raises the SDK lower bound
  from 3.0 to 3.7. `ffigen` is deliberately not a dev dependency — it needs
  Dart 3.10 — and is activated globally by `tool/generate_bindings.dart`
  instead.

### Internal

- The IPC sources moved from `lib/src/` into `lib/src/ipc/`, mirroring the new
  `lib/src/config/`. Nothing public moved: `package:miracle/miracle.dart`
  exports exactly the same names as before.

### Known upstream limitations

Two settings can be changed in memory but are not written by miracle's own
serialiser, so `save()` drops them. Both are documented on the members and
pinned by tests:

- `primaryButton` has neither a reader nor a writer in miracle's configuration
  file; it is set by plugins.
- `keyRepeatDelay` and `keyRepeatRate` are only written when `keymap` is also
  set, because miracle emits its whole `keyboard:` block behind that check.

## 2.1.0

Covers the urgency support added in
[miracle-wm#952](https://github.com/miracle-wm-org/miracle-wm/pull/952). A
window that asks to be raised while it is off screen — on a workspace its
output is not currently showing, or stashed on the scratchpad — is flagged as
urgent instead of being allowed to steal focus, and the flag clears once it is
focused. Urgency propagates up the tree, so a split container, workspace or
output is urgent whenever any node beneath it is.

The `urgent` fields were already decoded, but miracle always sent `false` for
them and this package documented them as legacy. They now carry real values,
and the two new `change` values that announce them are modelled.

### API additions

- `WindowChange.urgent` and `WorkspaceChange.urgent`. miracle emits both
  events together: the `window` event says which window changed, and the
  `workspace` event lets a bar that watches workspaces rather than windows see
  it without walking the tree. The workspace event carries no `old` workspace.
- `BaseNode.isUrgent`, a uniform accessor over `ContainerNode.urgent`,
  `WorkspaceNode.urgent` and `OutputNode.isUrgent`. `RootNode.isUrgent` is
  always `false`, since miracle sends no `urgent` key for the root.
- `BaseNode.urgentWindows`, the urgent windows at or below a node.

### Documentation

- `WorkspaceResult.urgent` no longer says it is legacy and always `false`.
- `ContainerNode.urgent`, `WorkspaceNode.urgent` and `OutputNode.isUrgent`
  describe when a window becomes urgent and how urgency propagates.
- `Criteria.urgent` records that miracle parses the criterion but never
  matches on it, so a command scoped by it selects nothing.
- `doc/ipc_coverage.md` gains an urgency section mapping each wire field and
  `change` value to its Dart API.

## 2.0.0

Audited the package against
[miracle's IPC reference](https://wiki.miracle-wm.org/develop/ipc/) and filled
in everything that was missing. `doc/ipc_coverage.md` now tracks every
message, event and command against the wiki so that a future gap is visible.

### Messages that were missing entirely

- **`GET_OUTPUTS` (3)** — `IpcType.ipcGetOutputs` existed, but there was no way
  to send it. Added `MiracleConnection.getOutputs()` and `OutputResult`.
- **`GET_DEBUG_STATE` (200)** — not modelled at all. Added
  `IpcType.ipcGetDebugState`, `MiracleConnection.getDebugState()`, `DebugState`
  and `DebugWindow`.
- **`PLUGIN_COMMAND` (201)** — not modelled at all. Added
  `IpcType.ipcPluginCommand`, `MiracleConnection.pluginCommand()` and
  `PluginCommandResult`.

### Events that were missing entirely

Only `workspace` was decoded; every other event threw an `UnsupportedError`
from inside the socket callback, which tore down the event stream. All nine
documented events are now decoded:

- `output` → `OutputEvent`
- `mode` → `ModeEvent`
- `window` → `WindowEvent`
- `binding` → `BindingEvent` and `BindingInfo`
- `shutdown` → `ShutdownEvent`
- `tick` → `TickEvent`
- `config_errors` (0x80000016) → `ConfigErrorsEvent` and `ConfigError`; the
  `IpcType` value did not exist either
- `plugin` (0x80000017) → `PluginEvent`; the `IpcType` value did not exist
  either

An event type this package does not model now arrives as an `UnknownEvent`,
and a payload that fails to decode is reported as a stream error instead of
killing the stream.

### Subscriptions that were missing

- `SubscriptionType.configErrors` (`config_errors`).
- Plugin namespace subscriptions: `subscribe(..., pluginNamespaces: [...])`
  and `subscribeToPlugin()`. A namespace that shadows a built-in event name is
  rejected with an `ArgumentError`, matching how miracle resolves them.
- `subscribeToAll()`, for everything except plugin namespaces.

### Commands

None of the fifteen documented commands were modelled; callers had to build
command strings by hand. Added `MiracleCommand`, with a named constructor for
every documented command and its options, plus `Criteria` for i3-style
container criteria, and `MiracleConnection.run`, `runAll` and `runOrThrow`.
`MiracleCommand.raw` still sends anything not covered.

### Bug fixes

- `CommandResult.parseError` was typed `String?`, but miracle sends a boolean,
  so **every failing command threw a `TypeError`** instead of returning a
  result. It is now a `bool`.
- A `workspace` event with `change: "reload"` carries no `current` workspace,
  and one with `change: "empty"` may carry no `old`. Decoding either threw.
  `WorkspaceEvent.current` is now nullable, and `WorkspaceChange` gained
  `move`, `reload` and `unknown`.
- `WorkspaceEventType.fromString` threw on any change it did not know.
- Two in-flight requests of the same type both completed with the first reply
  that arrived. Replies are now matched to requests in order.
- A request sent on a socket that then closed never completed, hanging the
  caller forever. Pending requests now complete with a
  `MiracleConnectionException`.
- `disconnect()` closed the event stream permanently, so a connection could
  never be reused. It now returns a `Future`, and `connect()` starts a fresh
  event stream.
- The socket path was read only from `MIRACLESOCK`. The documented `SWAYSOCK`
  and `I3SOCK` fallbacks are now used, and exposed as
  `MiracleConnection.resolveSocketPath`.
- An error raised while writing to a closed socket escaped as an unhandled
  async error.
- `OutputNode` read `dpkms`, which miracle never sends — it sends `dpms`, so
  the field was always `null`.
- `OutputMode.refreshMhz` and `OutputNode.scale` cast with `as double` and
  threw when miracle sent an integer, which it does for an inactive output's
  `scale` of `-1`.
- Node decoding required fields that miracle omits, so the container in a
  `window` event and any split container could not be decoded. Every model now
  decodes tolerantly.
- `BorderType` was missing `pixel` and `csd`, `ContainerLayout` was missing
  `output`, and `OutputTransform` was missing `flipped-90`, `flipped-180` and
  `flipped-270`. An unrecognized value no longer throws.

### API additions

- Typed event streams: `workspaceEvents`, `windowEvents`, `outputEvents`,
  `modeEvents`, `bindingEvents`, `shutdownEvents`, `tickEvents`,
  `configErrorEvents`, `pluginEvents`, `pluginEventsFor(namespace)` and
  `whereType<T>()`.
- Tree traversal on any node: `walk()`, `descendants`, `children`,
  `findById()`, `outputs`, `workspaces`, `windows` and `focusedNode`.
- `sendTick()` accepts a payload, which is what makes a tick useful as a
  round-trip marker. A `String` is sent verbatim; anything else is JSON
  encoded.
- `Event.raw` keeps the decoded payload of every event, as an escape hatch for
  fields this package does not model.
- `connect()` accepts `requestTimeout` and `onUnknownMessage`.
- `MiracleConnection.isConnected`.
- `Position` and `Size`, plus `==`, `hashCode` and `toJson` on `Rect`.
- `VersionResult.isAtLeast()`, for feature-gating on the running compositor.
- `ScratchpadState`, `SubpixelHinting`, `IdleInhibitors` and
  `WindowProperties` replace loosely typed fields.
- `MiracleConnectionException` and `MiracleCommandException` replace bare
  `Exception`s.

### Breaking changes

- `CommandResult.parseError` is a `bool` rather than a `String?`.
- `EventWorkspace` is now `WorkspaceEvent`, `WorkspaceEventType` is now
  `WorkspaceChange`, and `EventWorkspace.workspaceEventType` is now
  `WorkspaceEvent.change`. Deprecated aliases keep the old names compiling.
- `WorkspaceEvent.current` is nullable.
- `Event.fromJson` takes an `Object?`, since `config_errors` arrives as a JSON
  array rather than an object.
- `disconnect()` returns a `Future<void>`.
- `connect()` throws `MiracleConnectionException` rather than `Exception`.
- `OutputNode.currentMode` is nullable, `OutputNode.layout` is a
  `ContainerLayout` rather than a `String`, and `OutputNode.dpkms` is
  deprecated in favour of `OutputNode.dpms`.
- `ContainerNode.scratchpadState` is a `ScratchpadState?`,
  `ContainerNode.idleInhibitors` is an `IdleInhibitors?`, and
  `ContainerNode.windowProperties` is a `WindowProperties`.
- The library is split across several files under `lib/src/`. Everything is
  still exported from `package:miracle/miracle.dart`.

## 1.0.1

- Initial published API.

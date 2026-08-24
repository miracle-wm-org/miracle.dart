# Changelog

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

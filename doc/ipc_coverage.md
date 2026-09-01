# IPC coverage

This file tracks this package against
[miracle's IPC reference](https://wiki.miracle-wm.org/develop/ipc/), so that a
gap is visible rather than discovered at runtime.

Status is one of:

- **Covered** — there is a typed API for it, exercised by a test.
- **Not applicable** — miracle does not implement it.

## Messages

| Message | Status | Dart API |
| --- | --- | --- |
| [`RUN_COMMAND` (0)](https://wiki.miracle-wm.org/develop/ipc/run_command/) | Covered | `command`, `run`, `runAll`, `runOrThrow` → `List<CommandResult>` |
| [`GET_WORKSPACES` (1)](https://wiki.miracle-wm.org/develop/ipc/get_workspaces/) | Covered | `getWorkspaces` → `List<WorkspaceResult>` |
| [`SUBSCRIBE` (2)](https://wiki.miracle-wm.org/develop/ipc/subscribe/) | Covered | `subscribe`, `subscribeToPlugin`, `subscribeToAll` → `SubscribeResult` |
| [`GET_OUTPUTS` (3)](https://wiki.miracle-wm.org/develop/ipc/get_outputs/) | Covered | `getOutputs` → `List<OutputResult>` |
| [`GET_TREE` (4)](https://wiki.miracle-wm.org/develop/ipc/get_tree/) | Covered | `getTree` → `BaseNode` (`RootNode`, `OutputNode`, `WorkspaceNode`, `ContainerNode`) |
| [`GET_MARKS` (5)](https://wiki.miracle-wm.org/develop/ipc/get_marks/) | Covered | `getMarks` → `MarksResult` |
| [`GET_VERSION` (7)](https://wiki.miracle-wm.org/develop/ipc/get_version/) | Covered | `getVersion` → `VersionResult` |
| [`GET_BINDING_MODES` (8)](https://wiki.miracle-wm.org/develop/ipc/get_binding_modes/) | Covered | `getBindingModes` → `BindingModesResult` |
| [`SEND_TICK` (10)](https://wiki.miracle-wm.org/develop/ipc/send_tick/) | Covered | `sendTick([payload])` → `TickResult` |
| [`SYNC` (11)](https://wiki.miracle-wm.org/develop/ipc/sync/) | Covered | `sync` → `SyncResult` |
| [`GET_BINDING_STATE` (12)](https://wiki.miracle-wm.org/develop/ipc/get_binding_state/) | Covered | `getBindingState` → `BindingStateResult` |
| [`GET_DEBUG_STATE` (200)](https://wiki.miracle-wm.org/develop/ipc/get_debug_state/) | Covered | `getDebugState` → `DebugState` |
| [`PLUGIN_COMMAND` (201)](https://wiki.miracle-wm.org/develop/ipc/plugin_command/) | Covered | `pluginCommand` → `PluginCommandResult` |
| `GET_BAR_CONFIG` (6), `GET_CONFIG` (9) | Not applicable | miracle will never support these; `IpcType` names them only |
| `GET_INPUTS` (100), `GET_SEATS` (101) | Not applicable | unimplemented by miracle; `IpcType` names them only |

## Events

| Event | Status | Dart API |
| --- | --- | --- |
| [`workspace` (0x80000000)](https://wiki.miracle-wm.org/develop/ipc/events/workspace/) | Covered | `WorkspaceEvent`, `connection.workspaceEvents` |
| [`output` (0x80000001)](https://wiki.miracle-wm.org/develop/ipc/events/output/) | Covered | `OutputEvent`, `connection.outputEvents` |
| [`mode` (0x80000002)](https://wiki.miracle-wm.org/develop/ipc/events/mode/) | Covered | `ModeEvent`, `connection.modeEvents` |
| [`window` (0x80000003)](https://wiki.miracle-wm.org/develop/ipc/events/window/) | Covered | `WindowEvent`, `connection.windowEvents` |
| [`binding` (0x80000005)](https://wiki.miracle-wm.org/develop/ipc/events/binding/) | Covered | `BindingEvent`, `connection.bindingEvents` |
| [`shutdown` (0x80000006)](https://wiki.miracle-wm.org/develop/ipc/events/shutdown/) | Covered | `ShutdownEvent`, `connection.shutdownEvents` |
| [`tick` (0x80000007)](https://wiki.miracle-wm.org/develop/ipc/events/tick/) | Covered | `TickEvent`, `connection.tickEvents` |
| [`config_errors` (0x80000016)](https://wiki.miracle-wm.org/develop/ipc/events/config_errors/) | Covered | `ConfigErrorsEvent`, `connection.configErrorEvents` |
| [`plugin` (0x80000017)](https://wiki.miracle-wm.org/develop/ipc/events/plugin/) | Covered | `PluginEvent`, `connection.pluginEvents`, `connection.pluginEventsFor` |
| `input` (0x80000015) | Not applicable | miracle accepts the subscription but never emits it; arrives as `UnknownEvent` if it ever does |
| `barconfig_update` (0x80000004), `bar_state_update` (0x80000014) | Not applicable | never sent by miracle |

`change` values are modelled as enums (`WorkspaceChange`, `WindowChange`,
`OutputChange`, `ShutdownChange`), each with an `unknown` member so that a
value added by a newer miracle is surfaced rather than thrown.

## Urgency

A window becomes urgent when it asks to be raised while it is off screen — on
a workspace its output is not currently showing, or stashed on the scratchpad.
Rather than let it steal focus, miracle flags it; the flag clears once the
window is focused. Urgency propagates up the tree, so a split container,
workspace or output is urgent whenever any node beneath it is.

| Wire | Dart API |
| --- | --- |
| `urgent` on a `GET_TREE` node | `ContainerNode.urgent`, `WorkspaceNode.urgent`, `OutputNode.isUrgent`, or `BaseNode.isUrgent` for any of them |
| `urgent` on a `GET_WORKSPACES` entry | `WorkspaceResult.urgent` |
| `window` event, `change: "urgent"` | `WindowChange.urgent` |
| `workspace` event, `change: "urgent"` | `WorkspaceChange.urgent` |

miracle emits both events together: the window event says which window
changed, and the workspace event lets a bar that watches workspaces rather
than windows see it without walking the tree. The workspace event carries no
`old` workspace.

`BaseNode.urgentWindows` lists the urgent windows at or below a node.

## Commands

Every documented command has a named constructor on `MiracleCommand`.

| Command | Dart API |
| --- | --- |
| [`exec`](https://wiki.miracle-wm.org/develop/ipc/commands/exec/) | `MiracleCommand.exec` |
| [`split`](https://wiki.miracle-wm.org/develop/ipc/commands/split/) | `MiracleCommand.split` |
| [`layout`](https://wiki.miracle-wm.org/develop/ipc/commands/layout/) | `MiracleCommand.layout`, `.layoutToggleSplit`, `.layoutToggleAll`, `.layoutToggleAmong` |
| [`focus`](https://wiki.miracle-wm.org/develop/ipc/commands/focus/) | `MiracleCommand.focusDirection`, `.focusMatching`, `.focusWorkspaceOf`, `.focusTarget`, `.focusSibling`, `.focusOutput` |
| [`move`](https://wiki.miracle-wm.org/develop/ipc/commands/move/) | `MiracleCommand.move`, `.moveToPosition`, `.moveToCenter`, `.moveToMouse`, `.moveToMark`, `.moveToWorkspace`, `.moveToWorkspaceNumber`, `.moveToRelativeWorkspace`, `.moveToOutput`, `.moveWorkspaceToOutput` |
| [`mark`](https://wiki.miracle-wm.org/develop/ipc/commands/mark/) | `MiracleCommand.mark`, `.unmark` |
| [`resize`](https://wiki.miracle-wm.org/develop/ipc/commands/resize/) | `MiracleCommand.resize`, `.resizeSet` |
| [`swap`](https://wiki.miracle-wm.org/develop/ipc/commands/swap/) | `MiracleCommand.swapWithMark`, `.swapWithId` |
| [`sticky`](https://wiki.miracle-wm.org/develop/ipc/commands/sticky/) | `MiracleCommand.sticky` |
| [`workspace`](https://wiki.miracle-wm.org/develop/ipc/commands/workspace/) | `MiracleCommand.workspace`, `.workspaceNumber`, `.workspaceDirection`, `.workspaceBackAndForth` |
| [`rename`](https://wiki.miracle-wm.org/develop/ipc/commands/rename/) | `MiracleCommand.renameWorkspace` |
| [`gaps`](https://wiki.miracle-wm.org/develop/ipc/commands/gaps/) | `MiracleCommand.gaps` |
| [`scratchpad`](https://wiki.miracle-wm.org/develop/ipc/commands/scratchpad/) | `MiracleCommand.moveToScratchpad`, `.scratchpadShow` |
| [`nop`](https://wiki.miracle-wm.org/develop/ipc/commands/nop/) | `MiracleCommand.nop` |
| [`debug`](https://wiki.miracle-wm.org/develop/ipc/commands/debug/) | `MiracleCommand.debugOverlay` |

Command criteria (`[app_id="…"] focus`) are built with `Criteria`.

miracle's command parser also accepts commands the wiki does not document
(`fullscreen`, `floating`, `border`, `title_format`, `title_window_icon`,
`shm_log`, `debug_log`, `reload`, `restart`, `exit`, `input`, `i3_bar`). Those
have no named constructor; send them with `MiracleCommand.raw` or
`connection.command`.

## Where this package deviates from the wiki

These are places where the wiki and the compositor disagree. The package
follows the compositor and accepts the wiki's spelling where it can.

- The `binding` event's payload is documented with `binding.input_type`, but
  miracle emits `binding.type`. Both are read.
- A tree `output` node is documented with `dpkms`, but miracle emits `dpms`.
  Both are read; `OutputNode.dpms` is the accessor, and `dpkms` is deprecated.
- `GET_OUTPUTS` is documented with a `transform` field, which miracle does not
  currently emit, so `OutputResult.transform` is nullable.
- The `shutdown` event page is titled `0x80000008`, while the message list and
  the compositor both use `0x80000006`.
- The workspace `change` list documents `move`, and miracle additionally emits
  `empty` when a workspace is removed and `reload` (with no `current`
  workspace) when the configuration is reloaded.
- The window `change` list does not mention `floating`, which miracle emits
  when a window is floated or unfloated. `WindowChange.floating` covers it.
- `GET_WORKSPACES` documents `urgent` but the example omits it, and miracle
  omits several fields on split containers (`pid`, `app_id`,
  `scratchpad_state`). Every model decodes tolerantly for this reason.
- The root node of `GET_TREE` carries no `urgent` key at all, so
  `RootNode.isUrgent` is always `false`. Read urgency from the outputs below
  it instead.
- The `urgent` command criterion is parsed by miracle but never matched
  against, so `[urgent="latest"] focus` selects nothing. `Criteria.urgent`
  builds it for completeness and is documented as inert.

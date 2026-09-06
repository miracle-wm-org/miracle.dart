import 'miracle_ipc.dart';

/// IPC message types for miracle.
///
/// Callers should prefer using the methods on [MiracleConnection] to send
/// ipc commands.
///
/// See also:
/// * [MiracleConnection], a convenient wrapper around the raw miracle IPC
///   mechanism.
/// * <https://wiki.miracle-wm.org/develop/ipc/>, the protocol reference.
enum IpcType {
  // i3 command types - see i3's I3_REPLY_TYPE constants
  ipcCommand(0),
  ipcGetWorkspaces(1),
  ipcSubscribe(2),
  ipcGetOutputs(3),
  ipcGetTree(4),
  ipcGetMarks(5),

  /// Never supported by miracle.
  ipcGetBarConfig(6),
  ipcGetVersion(7),
  ipcGetBindingModes(8),

  /// Never supported by miracle.
  ipcGetConfig(9),
  ipcSendTick(10),
  ipcSync(11),
  ipcGetBindingState(12),

  // sway-specific command types
  /// Unimplemented by miracle, but may be implemented in the future.
  ipcGetInputs(100),

  /// Unimplemented by miracle, but may be implemented in the future.
  ipcGetSeats(101),

  // miracle-specific command types
  /// Retrieves a snapshot of debugging information.
  ///
  /// See also:
  /// * [MiracleConnection.getDebugState]
  ipcGetDebugState(200),

  /// Routes an arbitrary command to a plugin that has registered a namespace.
  ///
  /// See also:
  /// * [MiracleConnection.pluginCommand]
  ipcPluginCommand(201),

  // Events sent from miracle to clients. Events have the highest bit set.
  ipcEventWorkspace(0x80000000 | 0),
  ipcEventOutput(0x80000000 | 1),
  ipcEventMode(0x80000000 | 2),
  ipcEventWindow(0x80000000 | 3),

  /// Never sent by miracle.
  ipcEventBarconfigUpdate(0x80000000 | 4),
  ipcEventBinding(0x80000000 | 5),
  ipcEventShutdown(0x80000000 | 6),
  ipcEventTick(0x80000000 | 7),

  // sway-specific event types
  /// Never sent by miracle.
  ipcEventBarStateUpdate(0x80000000 | 20),

  /// Not sent by miracle yet, though it may be subscribed to.
  ipcEventInput(0x80000000 | 21),

  // miracle-specific event types
  /// Sent when the configuration is (re)loaded, carrying any parse errors.
  ipcEventConfigErrors(0x80000000 | 22),

  /// Sent when a plugin publishes an event on a subscribed namespace.
  ipcEventPlugin(0x80000000 | 23);

  const IpcType(this.value);

  /// The wire value of this message type.
  final int value;

  /// Whether this type identifies an event pushed by miracle.
  ///
  /// Events always have the highest bit set.
  bool get isEvent => (value & 0x80000000) != 0;

  /// Creates an [IpcType] from an integer value, or `null` if unrecognized.
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
/// Plugin events are not listed here: they are subscribed to per namespace.
///
/// See also:
/// * [MiracleConnection.subscribe], the method to subscribe to events
/// * [MiracleConnection.subscribeToPlugin], to subscribe to a plugin namespace
enum SubscriptionType {
  /// Sent whenever an event involving a workspace occurs.
  workspace('workspace'),

  /// Sent whenever an event involving an output occurs.
  output('output'),

  /// Sent whenever the binding mode changes.
  mode('mode'),

  /// Sent whenever an event involving a window occurs.
  window('window'),

  /// Sent whenever a key or mouse binding is triggered.
  binding('binding'),

  /// Sent right before miracle shuts down.
  shutdown('shutdown'),

  /// Sent when an IPC client sends a `SEND_TICK` message.
  tick('tick'),

  /// Sent when something related to input changes.
  ///
  /// miracle accepts the subscription but does not emit this event yet.
  input('input'),

  /// Sent when the configuration is (re)loaded, carrying any parse errors.
  ///
  /// Subscribing immediately delivers the errors of the most recent load.
  configErrors('config_errors');

  const SubscriptionType(this.wireName);

  /// The name used on the wire, e.g. `config_errors`.
  final String wireName;

  /// The [SubscriptionType] with the given [wireName], or `null`.
  static SubscriptionType? fromWireName(String wireName) {
    for (final type in SubscriptionType.values) {
      if (type.wireName == wireName) {
        return type;
      }
    }
    return null;
  }

  /// Whether [name] is reserved by a built-in event.
  ///
  /// Any other string is treated by miracle as a plugin namespace.
  static bool isReservedName(String name) => fromWireName(name) != null;
}

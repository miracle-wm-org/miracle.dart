import '../config/miracle_config.dart';
import 'json.dart';
import 'miracle_ipc.dart';

/// A set of keyboard modifiers, as reported by [MiracleConnection.getKeybinds].
///
/// The same shape is used for the primary modifier and for each keybind's own
/// modifiers, so both decode through this class.
///
/// [Modifier.fromString] drops names this package does not know about, so
/// [mask] is kept alongside [modifiers] as the lossless form.
///
/// See also:
/// * [KeybindsResult.primaryModifier], the modifier [Modifier.primary] stands
///   in for
/// * [Keybind.modifiers], the resolved modifiers of a single keybind
class KeybindModifiers {
  /// The modifiers, e.g. [Modifier.meta] or [Modifier.shift].
  ///
  /// Names this package does not know about are skipped; [mask] still carries
  /// their bits.
  final List<Modifier> modifiers;

  /// The bitmask of every modifier, including any this package cannot name.
  final int mask;

  KeybindModifiers({required this.modifiers, required this.mask});

  factory KeybindModifiers.fromJson(Map<String, dynamic> json) {
    return KeybindModifiers(
      modifiers: asStringList(json['modifiers'])
          .map(Modifier.fromString)
          .whereType<Modifier>()
          .toList(growable: false),
      mask: asInt(json['modifier_mask']),
    );
  }

  /// Whether [modifier] is part of this set.
  bool has(Modifier modifier) => modifiers.contains(modifier);

  @override
  String toString() => 'KeybindModifiers(modifiers: '
      '${modifiers.map((modifier) => modifier.wireName).toList()}, '
      'mask: $mask)';
}

/// A single configured keybinding, as reported by
/// [MiracleConnection.getKeybinds].
///
/// A keybind either runs one of miracle's built-in [action]s or a shell
/// [command]; the other is `null`.
///
/// See also:
/// * [KeybindsResult.keybinds], the list this comes from
class Keybind {
  /// The built-in command this keybind runs, if it runs one.
  ///
  /// `null` when the keybind runs a [command] instead, and also when miracle
  /// reported an action this package does not know about yet — check
  /// [actionName] to tell those apart.
  final BuiltInKeyCommand? action;

  /// The raw name of the built-in command, as miracle reported it.
  ///
  /// `null` when the keybind runs a [command] instead.
  final String? actionName;

  /// The shell command this keybind runs, if it runs one.
  ///
  /// `null` when the keybind runs an [action] instead.
  final String? command;

  /// The key event that triggers this keybind.
  ///
  /// `null` when miracle reported an event this package does not know about.
  final KeyboardAction? keyboardAction;

  /// The modifiers that must be held, with [Modifier.primary] already resolved
  /// to the configured primary modifier.
  final KeybindModifiers modifiers;

  /// The modifiers as written in the configuration file.
  ///
  /// Unlike [modifiers], this may contain the [Modifier.primary] sentinel.
  final List<Modifier> configuredModifiers;

  /// The xkb keysym of the key that must be pressed.
  final int xkbKeysym;

  /// The stringified keysym, e.g. `x` or `Return`.
  final String xkbKeysymName;

  Keybind({
    required this.action,
    required this.actionName,
    required this.command,
    required this.keyboardAction,
    required this.modifiers,
    required this.configuredModifiers,
    required this.xkbKeysym,
    required this.xkbKeysymName,
  });

  factory Keybind.fromJson(Map<String, dynamic> json) {
    final actionName = asStringOrNull(json['action']);
    return Keybind(
      action:
          actionName == null ? null : BuiltInKeyCommand.fromString(actionName),
      actionName: actionName,
      command: asStringOrNull(json['command']),
      keyboardAction:
          KeyboardAction.fromString(asString(json['keyboard_action'])),
      modifiers: KeybindModifiers.fromJson(json),
      configuredModifiers: asStringList(json['configured_modifiers'])
          .map(Modifier.fromString)
          .whereType<Modifier>()
          .toList(growable: false),
      xkbKeysym: asInt(json['xkb_keysym']),
      xkbKeysymName: asString(json['xkb_keysym_name']),
    );
  }

  @override
  String toString() => 'Keybind(modifiers: '
      '${modifiers.modifiers.map((modifier) => modifier.wireName).toList()}, '
      'key: "$xkbKeysymName", '
      '${actionName != null ? 'action: "$actionName"' : 'command: "$command"'})';
}

/// Created in response to a [MiracleConnection.getKeybinds] call.
///
/// This is the effective set of keybindings from miracle's configuration, so a
/// bar or a configuration tool can show what a key does right now without
/// reparsing the configuration file.
///
/// See also:
/// * [MiracleConnection.getKeybinds], to request the keybindings
class KeybindsResult {
  /// The modifier that [Modifier.primary] stands in for.
  final KeybindModifiers primaryModifier;

  /// Every configured keybinding.
  final List<Keybind> keybinds;

  KeybindsResult({required this.primaryModifier, required this.keybinds});

  factory KeybindsResult.fromJson(Map<String, dynamic> json) {
    return KeybindsResult(
      primaryModifier:
          KeybindModifiers.fromJson(asObject(json['primary_modifier'])),
      keybinds: asObjectList(json['keybinds'])
          .map(Keybind.fromJson)
          .toList(growable: false),
    );
  }

  @override
  String toString() => 'KeybindsResult(primaryModifier: $primaryModifier, '
      'keybinds: ${keybinds.length})';
}

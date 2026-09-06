part of 'miracle_config.dart';

/// A colour, with each component in the range 0.0 to 1.0.
///
/// This is deliberately not Flutter's `Color`: `package:miracle` is a plain
/// Dart package and does not depend on Flutter.
class RgbaColor {
  /// Creates a colour from its components.
  const RgbaColor({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 1.0,
  });

  /// Creates an opaque colour from 8-bit components.
  factory RgbaColor.fromBytes(int red, int green, int blue, [int alpha = 255]) {
    return RgbaColor(
      red: red / 255,
      green: green / 255,
      blue: blue / 255,
      alpha: alpha / 255,
    );
  }

  /// The red component, from 0.0 to 1.0.
  final double red;

  /// The green component, from 0.0 to 1.0.
  final double green;

  /// The blue component, from 0.0 to 1.0.
  final double blue;

  /// The alpha component, from 0.0 (transparent) to 1.0 (opaque).
  final double alpha;

  /// A copy of this colour with the given components replaced.
  RgbaColor copyWith({
    double? red,
    double? green,
    double? blue,
    double? alpha,
  }) {
    return RgbaColor(
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      alpha: alpha ?? this.alpha,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RgbaColor &&
      other.red == red &&
      other.green == green &&
      other.blue == blue &&
      other.alpha == alpha;

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);

  @override
  String toString() =>
      'RgbaColor(red: $red, green: $green, blue: $blue, alpha: $alpha)';
}

/// A problem found while loading or saving a configuration.
///
/// See also:
///
///  * [MiracleConfig.errors], the errors from the load that produced a config.
///  * [MiracleConfigSaveResult.errors], the errors from a failed save.
class MiracleConfigError {
  /// Creates an error report.
  const MiracleConfigError({
    required this.line,
    required this.column,
    required this.level,
    required this.filename,
    required this.message,
  });

  /// The line the problem was found on.
  final int line;

  /// The column the problem was found at.
  final int column;

  /// How serious the problem is.
  final MiracleConfigErrorLevel level;

  /// The file the problem was found in.
  final String filename;

  /// A human-readable description of the problem.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is MiracleConfigError &&
      other.line == line &&
      other.column == column &&
      other.level == level &&
      other.filename == filename &&
      other.message == message;

  @override
  int get hashCode => Object.hash(line, column, level, filename, message);

  @override
  String toString() =>
      'MiracleConfigError(${level.wireName}, '
      '$filename:$line:$column: $message)';
}

/// The outcome of [MiracleConfig.save].
class MiracleConfigSaveResult {
  /// Creates a save result.
  const MiracleConfigSaveResult({required this.success, required this.errors});

  /// Whether the configuration was written.
  final bool success;

  /// Anything that went wrong along the way.
  final List<MiracleConfigError> errors;

  @override
  String toString() =>
      'MiracleConfigSaveResult(success: $success, errors: $errors)';
}

/// A plugin miracle loads at startup.
class Plugin {
  /// Creates a plugin reference.
  const Plugin({required this.path});

  /// Where the plugin's shared object lives.
  final String path;

  /// A copy of this plugin with the given fields replaced.
  Plugin copyWith({String? path}) => Plugin(path: path ?? this.path);

  @override
  bool operator ==(Object other) => other is Plugin && other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'Plugin(path: $path)';
}

/// A key binding that runs a shell command.
///
/// See also:
///
///  * [KeyCommandOverride], which rebinds one of miracle's built-in commands.
class CustomKeyCommand {
  /// Creates a custom key binding.
  const CustomKeyCommand({
    required this.key,
    required this.command,
    this.action = KeyboardAction.down,
    this.modifiers = const <Modifier>{},
  });

  /// Which key event the binding fires on.
  final KeyboardAction action;

  /// The modifiers that must be held.
  final Set<Modifier> modifiers;

  /// The Linux key code, e.g. `KEY_F` from `linux/input-event-codes.h`.
  final int key;

  /// The shell command to run.
  final String command;

  /// A copy of this binding with the given fields replaced.
  CustomKeyCommand copyWith({
    KeyboardAction? action,
    Set<Modifier>? modifiers,
    int? key,
    String? command,
  }) {
    return CustomKeyCommand(
      action: action ?? this.action,
      modifiers: modifiers ?? this.modifiers,
      key: key ?? this.key,
      command: command ?? this.command,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CustomKeyCommand &&
      other.action == action &&
      _modifiersEqual(other.modifiers, modifiers) &&
      other.key == key &&
      other.command == command;

  @override
  int get hashCode =>
      Object.hash(action, _packModifiers(modifiers), key, command);

  @override
  String toString() =>
      'CustomKeyCommand(action: ${action.wireName}, '
      'modifiers: $modifiers, key: $key, command: $command)';
}

/// A rebinding of one of miracle's built-in commands.
class KeyCommandOverride {
  /// Creates an override of a built-in command's binding.
  const KeyCommandOverride({
    required this.key,
    required this.command,
    this.action = KeyboardAction.down,
    this.modifiers = const <Modifier>{},
  });

  /// Which key event the binding fires on.
  final KeyboardAction action;

  /// The modifiers that must be held.
  final Set<Modifier> modifiers;

  /// The Linux key code, e.g. `KEY_F` from `linux/input-event-codes.h`.
  final int key;

  /// The built-in command to run.
  final BuiltInKeyCommand command;

  /// A copy of this override with the given fields replaced.
  KeyCommandOverride copyWith({
    KeyboardAction? action,
    Set<Modifier>? modifiers,
    int? key,
    BuiltInKeyCommand? command,
  }) {
    return KeyCommandOverride(
      action: action ?? this.action,
      modifiers: modifiers ?? this.modifiers,
      key: key ?? this.key,
      command: command ?? this.command,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeyCommandOverride &&
      other.action == action &&
      _modifiersEqual(other.modifiers, modifiers) &&
      other.key == key &&
      other.command == command;

  @override
  int get hashCode =>
      Object.hash(action, _packModifiers(modifiers), key, command);

  @override
  String toString() =>
      'KeyCommandOverride(action: ${action.wireName}, '
      'modifiers: $modifiers, key: $key, command: ${command.wireName})';
}

/// An application miracle launches at startup.
class StartupApp {
  /// Creates a startup application entry.
  const StartupApp({
    required this.command,
    this.restartOnDeath = false,
    this.noStartupId = false,
    this.shouldHaltCompositorOnDeath = false,
    this.inSystemdScope = false,
  });

  /// The command to run.
  final String command;

  /// Whether to relaunch the application if it exits.
  final bool restartOnDeath;

  /// Whether to launch without a startup notification id.
  final bool noStartupId;

  /// Whether miracle should shut down when this application exits.
  final bool shouldHaltCompositorOnDeath;

  /// Whether to launch the application inside a systemd scope.
  final bool inSystemdScope;

  /// A copy of this entry with the given fields replaced.
  StartupApp copyWith({
    String? command,
    bool? restartOnDeath,
    bool? noStartupId,
    bool? shouldHaltCompositorOnDeath,
    bool? inSystemdScope,
  }) {
    return StartupApp(
      command: command ?? this.command,
      restartOnDeath: restartOnDeath ?? this.restartOnDeath,
      noStartupId: noStartupId ?? this.noStartupId,
      shouldHaltCompositorOnDeath:
          shouldHaltCompositorOnDeath ?? this.shouldHaltCompositorOnDeath,
      inSystemdScope: inSystemdScope ?? this.inSystemdScope,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StartupApp &&
      other.command == command &&
      other.restartOnDeath == restartOnDeath &&
      other.noStartupId == noStartupId &&
      other.shouldHaltCompositorOnDeath == shouldHaltCompositorOnDeath &&
      other.inSystemdScope == inSystemdScope;

  @override
  int get hashCode => Object.hash(
    command,
    restartOnDeath,
    noStartupId,
    shouldHaltCompositorOnDeath,
    inSystemdScope,
  );

  @override
  String toString() =>
      'StartupApp(command: $command, '
      'restartOnDeath: $restartOnDeath, noStartupId: $noStartupId, '
      'shouldHaltCompositorOnDeath: $shouldHaltCompositorOnDeath, '
      'inSystemdScope: $inSystemdScope)';
}

/// An environment variable miracle sets for the applications it launches.
class EnvironmentVariable {
  /// Creates an environment variable entry.
  const EnvironmentVariable({required this.key, required this.value});

  /// The variable's name.
  final String key;

  /// The variable's value.
  final String value;

  /// A copy of this entry with the given fields replaced.
  EnvironmentVariable copyWith({String? key, String? value}) =>
      EnvironmentVariable(key: key ?? this.key, value: value ?? this.value);

  @override
  bool operator ==(Object other) =>
      other is EnvironmentVariable && other.key == key && other.value == value;

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() => 'EnvironmentVariable(key: $key, value: $value)';
}

/// Settings for a single workspace.
///
/// At least one of [number] and [name] must be set for miracle to be able to
/// match the configuration to a workspace.
class WorkspaceConfig {
  /// Creates a workspace configuration.
  const WorkspaceConfig({this.number, this.name});

  /// The workspace this applies to, by number.
  final int? number;

  /// The workspace this applies to, by name.
  final String? name;

  /// A copy of this configuration with the given fields replaced.
  ///
  /// Passing `clearNumber` or `clearName` unsets the corresponding field,
  /// which passing `null` cannot express.
  WorkspaceConfig copyWith({
    int? number,
    String? name,
    bool clearNumber = false,
    bool clearName = false,
  }) {
    return WorkspaceConfig(
      number: clearNumber ? null : number ?? this.number,
      name: clearName ? null : name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorkspaceConfig && other.number == number && other.name == name;

  @override
  int get hashCode => Object.hash(number, name);

  @override
  String toString() => 'WorkspaceConfig(number: $number, name: $name)';
}

/// One of the concurrent animations that make up an [AnimateableEvent].
///
/// The `c1` to `d1` coefficients parameterise the easing curve; see
/// <https://easings.net/> for what each one does. Curves that do not use a
/// coefficient ignore it.
class BuiltInAnimation {
  /// Creates an animation.
  const BuiltInAnimation({
    required this.type,
    required this.function,
    this.c1 = 0.0,
    this.c2 = 0.0,
    this.c3 = 0.0,
    this.c4 = 0.0,
    this.c5 = 0.0,
    this.n1 = 0.0,
    this.d1 = 0.0,
  });

  /// What the animation moves.
  final AnimationType type;

  /// The easing curve the animation follows.
  final EaseFunction function;

  /// The `c1` easing coefficient.
  final double c1;

  /// The `c2` easing coefficient.
  final double c2;

  /// The `c3` easing coefficient.
  final double c3;

  /// The `c4` easing coefficient.
  final double c4;

  /// The `c5` easing coefficient.
  final double c5;

  /// The `n1` easing coefficient.
  final double n1;

  /// The `d1` easing coefficient.
  final double d1;

  /// A copy of this animation with the given fields replaced.
  BuiltInAnimation copyWith({
    AnimationType? type,
    EaseFunction? function,
    double? c1,
    double? c2,
    double? c3,
    double? c4,
    double? c5,
    double? n1,
    double? d1,
  }) {
    return BuiltInAnimation(
      type: type ?? this.type,
      function: function ?? this.function,
      c1: c1 ?? this.c1,
      c2: c2 ?? this.c2,
      c3: c3 ?? this.c3,
      c4: c4 ?? this.c4,
      c5: c5 ?? this.c5,
      n1: n1 ?? this.n1,
      d1: d1 ?? this.d1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BuiltInAnimation &&
      other.type == type &&
      other.function == function &&
      other.c1 == c1 &&
      other.c2 == c2 &&
      other.c3 == c3 &&
      other.c4 == c4 &&
      other.c5 == c5 &&
      other.n1 == n1 &&
      other.d1 == d1;

  @override
  int get hashCode => Object.hash(type, function, c1, c2, c3, c4, c5, n1, d1);

  @override
  String toString() =>
      'BuiltInAnimation(type: ${type.wireName}, '
      'function: ${function.wireName})';
}

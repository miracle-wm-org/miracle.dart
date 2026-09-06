/// Reading and writing miracle-wm's configuration file.
///
/// The entry point is [MiracleConfig], which wraps the `libmiracle-wm-c`
/// configuration library that ships with miracle-wm:
///
/// ```dart
/// final config = MiracleConfig.loadDefault();
/// try {
///   config.innerGapsX = 10;
///   config.terminal = 'kitty';
///   config.startupApps.add(const StartupApp(command: 'nm-applet'));
///   config.save();
/// } finally {
///   config.dispose();
/// }
/// ```
///
/// Loading needs `libmiracle-wm-c` on the system; check
/// [MiracleConfig.isAvailable] first if that is not guaranteed.
library;

import 'dart:collection';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart';

part 'collections.dart';
part 'enums.dart';
part 'native.dart';
part 'types.dart';
part 'views.dart';

/// Thrown when the configuration library is unavailable or cannot be used.
///
/// See also:
///
///  * [MiracleConfig.isAvailable], which reports the same condition without
///    throwing.
class MiracleConfigException implements Exception {
  /// Creates an exception with the given [message].
  MiracleConfigException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'MiracleConfigException: $message';
}

/// Miracle-wm's configuration, loaded from disk.
///
/// Properties read and write the loaded configuration directly; nothing is
/// written back to disk until [save] is called. The underlying native
/// configuration is freed by [dispose], and by a [Finalizer] if that is
/// forgotten — but relying on the finalizer means holding native memory for an
/// unbounded time, so prefer disposing explicitly.
///
/// See also:
///
///  * [MiracleConnection], for talking to a running miracle-wm rather than to
///    its configuration file.
class MiracleConfig {
  MiracleConfig._(this.path, this._result, this._dataPointer, this.errors) {
    _finalizer.attach(this, _result, detach: this);
  }

  /// Frees the native configuration of a [MiracleConfig] that was collected
  /// without being disposed.
  static final Finalizer<Pointer<miracle_config_load_result_t>> _finalizer =
      Finalizer<Pointer<miracle_config_load_result_t>>(
        (pointer) => _native.miracle_config_free(pointer),
      );

  /// Whether `libmiracle-wm-c` could be loaded.
  ///
  /// Everything else on this class throws a [MiracleConfigException] when this
  /// is false, so it is worth checking on systems where miracle-wm may not be
  /// installed. Importing `package:miracle` never loads the library, so the
  /// rest of the package works regardless.
  static bool get isAvailable {
    _ensureLoaded();
    return _bindings != null;
  }

  /// Where miracle looks for its configuration by default.
  static String get defaultConfigPath =>
      _toDartString(_native.miracle_config_path());

  /// Loads the configuration at [path].
  ///
  /// A configuration that could not be parsed cleanly still loads; look at
  /// [errors] for what went wrong. This throws only when the configuration
  /// library is missing or refuses to produce a result at all.
  factory MiracleConfig.load(String path) {
    final bindings = _native;
    final result = _withNativeString(
      path,
      (native) => bindings.miracle_config_load(native),
    );

    if (result == nullptr) {
      throw MiracleConfigException(
        'Could not load a configuration from $path.',
      );
    }

    final errors = _readErrors(
      bindings.miracle_config_get_error_count(result),
      (index) => bindings.miracle_config_get_error(result, index),
    );

    return MiracleConfig._(
      path,
      result,
      bindings.miracle_config_get_data(result),
      errors,
    );
  }

  /// Loads the configuration at [defaultConfigPath].
  factory MiracleConfig.loadDefault() => MiracleConfig.load(defaultConfigPath);

  /// The file this configuration was loaded from.
  final String path;

  /// Anything miracle objected to while loading this configuration.
  ///
  /// Warnings and errors both appear here; see [hasErrors] for whether any of
  /// them were serious.
  final List<MiracleConfigError> errors;

  final Pointer<miracle_config_load_result_t> _result;
  final Pointer<miracle_config_data_t> _dataPointer;
  bool _disposed = false;

  /// Whether any of [errors] is an error rather than a warning.
  bool get hasErrors =>
      errors.any((error) => error.level == MiracleConfigErrorLevel.error);

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// The native configuration, guarded against use after [dispose].
  ///
  /// Passing a freed pointer to the C library would be a segfault rather than
  /// an exception, so every accessor goes through here.
  Pointer<miracle_config_data_t> get _data {
    if (_disposed) {
      throw StateError('This MiracleConfig has been disposed.');
    }
    return _dataPointer;
  }

  /// Writes the configuration to [path], defaulting to the file it was loaded
  /// from.
  MiracleConfigSaveResult save([String? path]) {
    final data = _data;
    final target = path ?? this.path;
    final result = _withNativeString(
      target,
      (native) => _native.miracle_config_save(native, data),
    );

    if (result == nullptr) {
      return MiracleConfigSaveResult(
        success: false,
        errors: List<MiracleConfigError>.unmodifiable(<MiracleConfigError>[
          MiracleConfigError(
            line: 0,
            column: 0,
            level: MiracleConfigErrorLevel.error,
            filename: target,
            message: 'The configuration library returned no save result.',
          ),
        ]),
      );
    }

    try {
      return MiracleConfigSaveResult(
        success: result.ref.success,
        errors: _readErrors(
          _native.miracle_save_result_get_error_count(result),
          (index) => _native.miracle_save_result_get_error(result, index),
        ),
      );
    } finally {
      _native.miracle_save_result_free(result);
    }
  }

  /// Frees the native configuration.
  ///
  /// Every other member throws a [StateError] afterwards. Calling this more
  /// than once does nothing.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _finalizer.detach(this);
    _native.miracle_config_free(_result);
  }

  /// The modifier that miracle's own key bindings are built on.
  Modifier get primaryModifier =>
      Modifier.fromValue(_native.miracle_config_get_primary_modifier(_data)) ??
      Modifier.primary;
  set primaryModifier(Modifier value) =>
      _native.miracle_config_set_primary_modifier(_data, value.value);

  /// The mouse button that miracle's own pointer bindings are built on.
  ///
  /// Miracle has neither a reader nor a writer for this in its configuration
  /// file — it is set by plugins — so changing it here lasts only as long as
  /// this object does and is not written by [save].
  MouseButton get primaryButton =>
      MouseButton.fromValue(_native.miracle_config_get_primary_button(_data)) ??
      MouseButton.primary;
  set primaryButton(MouseButton value) =>
      _native.miracle_config_set_primary_button(_data, value.value);

  /// The modifier held to move windows around.
  Modifier get moveModifier =>
      Modifier.fromValue(_native.miracle_config_get_move_modifier(_data)) ??
      Modifier.primary;
  set moveModifier(Modifier value) =>
      _native.miracle_config_set_move_modifier(_data, value.value);

  /// The horizontal gap between adjacent windows, in pixels.
  int get innerGapsX => _native.miracle_config_get_inner_gaps_x(_data);
  set innerGapsX(int value) =>
      _native.miracle_config_set_inner_gaps_x(_data, value);

  /// The vertical gap between adjacent windows, in pixels.
  int get innerGapsY => _native.miracle_config_get_inner_gaps_y(_data);
  set innerGapsY(int value) =>
      _native.miracle_config_set_inner_gaps_y(_data, value);

  /// The horizontal gap between the windows and the screen edge, in pixels.
  int get outerGapsX => _native.miracle_config_get_outer_gaps_x(_data);
  set outerGapsX(int value) =>
      _native.miracle_config_set_outer_gaps_x(_data, value);

  /// The vertical gap between the windows and the screen edge, in pixels.
  int get outerGapsY => _native.miracle_config_get_outer_gaps_y(_data);
  set outerGapsY(int value) =>
      _native.miracle_config_set_outer_gaps_y(_data, value);

  /// How far a resize keybinding resizes a window, in pixels.
  int get resizeJump => _native.miracle_config_get_resize_jump(_data);
  set resizeJump(int value) =>
      _native.miracle_config_set_resize_jump(_data, value);

  /// Whether miracle animates anything at all.
  ///
  /// See also:
  ///
  ///  * [animateableEvents], for what each animation looks like.
  bool get animationsEnabled =>
      _native.miracle_config_get_animations_enabled(_data);
  set animationsEnabled(bool value) =>
      _native.miracle_config_set_animations_enabled(_data, value);

  /// The terminal emulator miracle launches, or `null` to use its default.
  ///
  /// Miracle checks that the program exists when it *loads* a configuration,
  /// and falls back to its own default when the check fails. That check shells
  /// out through `system()`, which is unreliable inside a Dart process — the
  /// Dart VM reaps child processes itself, so the check can lose the race and
  /// report an installed terminal as missing. Setting this and reading it back
  /// is unaffected; only reloading a saved file is.
  String? get terminal =>
      _toDartStringOrNull(_native.miracle_config_get_terminal(_data));
  set terminal(String? value) => _withNativeString(
    value,
    (native) => _native.miracle_config_set_terminal(_data, native),
  );

  /// How long a held key waits before it starts repeating, in milliseconds.
  ///
  /// Miracle writes its keyboard settings only when a keymap is configured, so
  /// [save] drops this unless [keymap] is set as well.
  int get keyRepeatDelay => _native.miracle_config_get_key_repeat_delay(_data);
  set keyRepeatDelay(int value) =>
      _native.miracle_config_set_key_repeat_delay(_data, value);

  /// How many times a second a held key repeats.
  ///
  /// As with [keyRepeatDelay], [save] drops this unless [keymap] is set.
  int get keyRepeatRate => _native.miracle_config_get_key_repeat_rate(_data);
  set keyRepeatRate(int value) =>
      _native.miracle_config_set_key_repeat_rate(_data, value);

  /// Whether selecting the current workspace switches back to the previous one.
  bool get workspaceBackAndForth =>
      _native.miracle_config_get_workspace_back_and_forth(_data);
  set workspaceBackAndForth(bool value) =>
      _native.miracle_config_set_workspace_back_and_forth(_data, value);

  /// The colour the compositor clears the screen to.
  ///
  /// The compositor's background is opaque, so the alpha component of [value]
  /// is ignored and this always reads back as fully opaque.
  RgbaColor get backgroundColor {
    final color = _native.miracle_config_get_background_color(_data);
    return RgbaColor(red: color.r, green: color.g, blue: color.b);
  }

  set backgroundColor(RgbaColor value) {
    final pointer = calloc<miracle_color_rgb_t>();
    try {
      pointer.ref
        ..r = value.red
        ..g = value.green
        ..b = value.blue;
      _native.miracle_config_set_background_color(_data, pointer.ref);
    } finally {
      calloc.free(pointer);
    }
  }

  /// The border drawn around windows.
  late final BorderConfig border = BorderConfig._(this);

  /// Dragging windows with the pointer.
  late final DragAndDrop dragAndDrop = DragAndDrop._(this);

  /// Pointer device settings.
  late final MouseConfig mouse = MouseConfig._(this);

  /// Touchpad settings.
  late final TouchpadConfig touchpad = TouchpadConfig._(this);

  /// The keyboard layout.
  late final Keymap keymap = Keymap._(this);

  /// The pointer cursor.
  late final Cursor cursor = Cursor._(this);

  /// The screen magnifier.
  late final Magnifier magnifier = Magnifier._(this);

  /// Clicking by resting the pointer still.
  late final HoverClick hoverClick = HoverClick._(this);

  /// Right-clicking by holding the primary button down.
  late final SimulatedSecondaryClick simulatedSecondaryClick =
      SimulatedSecondaryClick._(this);

  /// Ignoring keys that are not held down long enough.
  late final SlowKeys slowKeys = SlowKeys._(this);

  /// Latching modifiers so they need not be held.
  late final StickyKeys stickyKeys = StickyKeys._(this);

  /// A shader applied to the whole output.
  late final OutputFilter outputFilter = OutputFilter._(this);

  /// The other configuration files merged into this one.
  ///
  /// Writing to the returned list changes the configuration.
  late final List<String> includes = _Includes._(this);

  /// The plugins miracle loads.
  late final List<Plugin> plugins = _Plugins._(this);

  /// The key bindings that run shell commands.
  late final List<CustomKeyCommand> customKeyCommands = _CustomKeyCommands._(
    this,
  );

  /// The rebindings of miracle's built-in commands.
  late final List<KeyCommandOverride> builtInKeyCommandOverrides =
      _KeyCommandOverrides._(this);

  /// The applications miracle launches at startup.
  late final List<StartupApp> startupApps = _StartupApps._(this);

  /// The environment variables miracle sets for the applications it launches.
  late final List<EnvironmentVariable> environmentVariables =
      _EnvironmentVariables._(this);

  /// The per-workspace settings.
  late final List<WorkspaceConfig> workspaceConfigs = _WorkspaceConfigs._(this);

  /// The events miracle can animate.
  ///
  /// Miracle defines a fixed set of these, so the list cannot grow or shrink;
  /// mutate the [AnimateableEvent]s themselves instead.
  late final List<AnimateableEvent> animateableEvents = _AnimateableEvents._(
    this,
  );

  @override
  String toString() => 'MiracleConfig(path: $path, errors: ${errors.length})';
}

/// Copies [count] error structs out of the C library.
///
/// The library hands back a pointer to a single `static thread_local` struct
/// that the next call overwrites, so each one has to be read out immediately
/// rather than collected up as pointers.
List<MiracleConfigError> _readErrors(
  int count,
  Pointer<miracle_config_error_t> Function(int) read,
) {
  final errors = <MiracleConfigError>[];
  for (var index = 0; index < count; index++) {
    final pointer = read(index);
    if (pointer == nullptr) continue;
    errors.add(
      MiracleConfigError(
        line: pointer.ref.line,
        column: pointer.ref.column,
        level:
            MiracleConfigErrorLevel.fromValue(pointer.ref.levelAsInt) ??
            MiracleConfigErrorLevel.error,
        filename: _toDartString(pointer.ref.filename),
        message: _toDartString(pointer.ref.message),
      ),
    );
  }
  return List<MiracleConfigError>.unmodifiable(errors);
}

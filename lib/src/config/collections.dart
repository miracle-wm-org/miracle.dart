part of 'miracle_config.dart';

/// A [List] view over one of the configuration's native collections.
///
/// Every operation goes straight through to the C library, so a mutation is
/// visible to the next read and is included by [MiracleConfig.save].
abstract class _NativeList<E> extends ListBase<E> {
  /// Removes the element at [index] from the underlying collection.
  ///
  /// Callers go through [removeAt], which returns the removed element.
  void _removeAt(int index);

  @override
  set length(int newLength) {
    RangeError.checkNotNegative(newLength, 'newLength');
    if (newLength > length) {
      throw UnsupportedError(
        'Cannot grow a native configuration list by setting its length; '
        'use add() instead.',
      );
    }
    while (length > newLength) {
      _removeAt(length - 1);
    }
  }

  @override
  E removeAt(int index) {
    _checkIndex(index, length);
    final removed = this[index];
    _removeAt(index);
    return removed;
  }

  @override
  bool remove(Object? element) {
    final index = indexOf(element as E);
    if (index < 0) return false;
    _removeAt(index);
    return true;
  }

  @override
  void insert(int index, E element) {
    if (index < 0 || index > length) {
      throw RangeError.range(index, 0, length, 'index');
    }
    // The C library only appends, so append and shift the tail along.
    add(element);
    for (var i = length - 1; i > index; i--) {
      this[i] = this[i - 1];
    }
    this[index] = element;
  }
}

/// The other configuration files miracle merges into this one.
class _Includes extends _NativeList<String> {
  _Includes._(this._config);

  final MiracleConfig _config;

  @override
  int get length => _native.miracle_config_get_num_includes(_config._data);

  @override
  String operator [](int index) {
    _checkIndex(index, length);
    return _toDartString(
      _native.miracle_config_get_include(_config._data, index),
    );
  }

  @override
  void operator []=(int index, String value) {
    _checkIndex(index, length);
    _withNativeString(
      value,
      (string) =>
          _native.miracle_config_set_include(_config._data, string, index),
    );
  }

  @override
  void add(String element) => _withNativeString(
    element,
    (string) =>
        _native.miracle_config_add_include(_config._data, string, length),
  );

  @override
  void insert(int index, String element) {
    if (index < 0 || index > length) {
      throw RangeError.range(index, 0, length, 'index');
    }
    // Unlike its siblings, this one inserts at an index natively.
    _withNativeString(
      element,
      (string) =>
          _native.miracle_config_add_include(_config._data, string, index),
    );
  }

  @override
  void _removeAt(int index) =>
      _native.miracle_config_remove_include(_config._data, index);
}

/// The plugins miracle loads.
class _Plugins extends _NativeList<Plugin> {
  _Plugins._(this._config);

  final MiracleConfig _config;

  @override
  int get length => _native.miracle_config_get_plugin_count(_config._data);

  @override
  Plugin operator [](int index) {
    _checkIndex(index, length);
    final plugin = _native.miracle_config_get_plugin(_config._data, index);
    return Plugin(path: _toDartString(plugin.path));
  }

  @override
  void operator []=(int index, Plugin value) {
    _checkIndex(index, length);
    _withPlugin(
      value,
      (pointer) =>
          _native.miracle_config_set_plugin(_config._data, index, pointer),
    );
  }

  @override
  void add(Plugin element) => _withPlugin(
    element,
    (pointer) => _native.miracle_config_add_plugin(_config._data, pointer),
  );

  @override
  void _removeAt(int index) =>
      _native.miracle_config_remove_plugin(_config._data, index);

  void _withPlugin(
    Plugin plugin,
    void Function(Pointer<miracle_plugin_t>) body,
  ) {
    _withNativeString(plugin.path, (path) {
      final pointer = calloc<miracle_plugin_t>();
      try {
        pointer.ref.path = path;
        body(pointer);
      } finally {
        calloc.free(pointer);
      }
    });
  }
}

/// The key bindings that run shell commands.
class _CustomKeyCommands extends _NativeList<CustomKeyCommand> {
  _CustomKeyCommands._(this._config);

  final MiracleConfig _config;

  @override
  int get length =>
      _native.miracle_config_get_custom_key_command_count(_config._data);

  @override
  CustomKeyCommand operator [](int index) {
    _checkIndex(index, length);
    final command = _native.miracle_config_get_custom_key_command(
      _config._data,
      index,
    );
    return CustomKeyCommand(
      action: KeyboardAction.fromValue(command.action) ?? KeyboardAction.down,
      modifiers: _unpackModifiers(command.modifiers),
      key: command.key,
      command: _toDartString(command.command),
    );
  }

  @override
  void operator []=(int index, CustomKeyCommand value) {
    _checkIndex(index, length);
    _withCommand(
      value,
      (pointer) => _native.miracle_config_edit_custom_key_command(
        _config._data,
        index,
        pointer,
      ),
    );
  }

  @override
  void add(CustomKeyCommand element) => _withCommand(
    element,
    (pointer) =>
        _native.miracle_config_add_custom_key_command(_config._data, pointer),
  );

  @override
  void _removeAt(int index) =>
      _native.miracle_config_remove_custom_key_command(_config._data, index);

  void _withCommand(
    CustomKeyCommand command,
    void Function(Pointer<miracle_custom_key_command_t>) body,
  ) {
    _withNativeString(command.command, (string) {
      final pointer = calloc<miracle_custom_key_command_t>();
      try {
        pointer.ref
          ..action = command.action.value
          ..modifiers = _packModifiers(command.modifiers)
          ..key = command.key
          ..command = string;
        body(pointer);
      } finally {
        calloc.free(pointer);
      }
    });
  }
}

/// The rebindings of miracle's built-in commands.
class _KeyCommandOverrides extends _NativeList<KeyCommandOverride> {
  _KeyCommandOverrides._(this._config);

  final MiracleConfig _config;

  @override
  int get length => _native
      .miracle_config_get_built_in_key_command_override_count(_config._data);

  @override
  KeyCommandOverride operator [](int index) {
    _checkIndex(index, length);
    final override = _native.miracle_config_get_built_in_key_command_override(
      _config._data,
      index,
    );
    return KeyCommandOverride(
      action: KeyboardAction.fromValue(override.action) ?? KeyboardAction.down,
      modifiers: _unpackModifiers(override.modifiers),
      key: override.key,
      command:
          BuiltInKeyCommand.fromValue(override.command) ??
          BuiltInKeyCommand.terminal,
    );
  }

  @override
  void operator []=(int index, KeyCommandOverride value) {
    _checkIndex(index, length);
    _withOverride(
      value,
      (pointer) => _native.miracle_config_set_built_in_key_command_override(
        _config._data,
        index,
        pointer,
      ),
    );
  }

  @override
  void add(KeyCommandOverride element) => _withOverride(
    element,
    (pointer) => _native.miracle_config_add_built_in_key_command_override(
      _config._data,
      pointer,
    ),
  );

  @override
  void _removeAt(int index) =>
      _native.miracle_config_remove_built_in_key_command_override(
        _config._data,
        index,
      );

  void _withOverride(
    KeyCommandOverride override,
    void Function(Pointer<miracle_built_in_key_command_override_t>) body,
  ) {
    final pointer = calloc<miracle_built_in_key_command_override_t>();
    try {
      pointer.ref
        ..action = override.action.value
        ..modifiers = _packModifiers(override.modifiers)
        ..key = override.key
        ..command = override.command.value;
      body(pointer);
    } finally {
      calloc.free(pointer);
    }
  }
}

/// The applications miracle launches at startup.
class _StartupApps extends _NativeList<StartupApp> {
  _StartupApps._(this._config);

  final MiracleConfig _config;

  @override
  int get length => _native.miracle_config_get_startup_app_count(_config._data);

  @override
  StartupApp operator [](int index) {
    _checkIndex(index, length);
    final app = _native.miracle_config_get_startup_app(_config._data, index);
    return StartupApp(
      command: _toDartString(app.command),
      restartOnDeath: app.restart_on_death,
      noStartupId: app.no_startup_id,
      shouldHaltCompositorOnDeath: app.should_halt_compositor_on_death,
      inSystemdScope: app.in_systemd_scope,
    );
  }

  @override
  void operator []=(int index, StartupApp value) {
    _checkIndex(index, length);
    _withApp(
      value,
      (pointer) =>
          _native.miracle_config_set_startup_app(_config._data, index, pointer),
    );
  }

  @override
  void add(StartupApp element) => _withApp(
    element,
    (pointer) => _native.miracle_config_add_startup_app(_config._data, pointer),
  );

  @override
  void _removeAt(int index) =>
      _native.miracle_config_remove_startup_app(_config._data, index);

  void _withApp(
    StartupApp app,
    void Function(Pointer<miracle_startup_app_t>) body,
  ) {
    _withNativeString(app.command, (command) {
      final pointer = calloc<miracle_startup_app_t>();
      try {
        pointer.ref
          ..command = command
          ..restart_on_death = app.restartOnDeath
          ..no_startup_id = app.noStartupId
          ..should_halt_compositor_on_death = app.shouldHaltCompositorOnDeath
          ..in_systemd_scope = app.inSystemdScope;
        body(pointer);
      } finally {
        calloc.free(pointer);
      }
    });
  }
}

/// The environment variables miracle sets for the applications it launches.
class _EnvironmentVariables extends _NativeList<EnvironmentVariable> {
  _EnvironmentVariables._(this._config);

  final MiracleConfig _config;

  @override
  int get length =>
      _native.miracle_config_get_environment_variable_count(_config._data);

  @override
  EnvironmentVariable operator [](int index) {
    _checkIndex(index, length);
    final variable = _native.miracle_config_get_environment_variable(
      _config._data,
      index,
    );
    return EnvironmentVariable(
      key: _toDartString(variable.key),
      value: _toDartString(variable.value),
    );
  }

  @override
  void operator []=(int index, EnvironmentVariable value) {
    _checkIndex(index, length);
    _withVariable(
      value,
      (pointer) => _native.miracle_config_set_environment_variable(
        _config._data,
        index,
        pointer,
      ),
    );
  }

  @override
  void add(EnvironmentVariable element) => _withVariable(
    element,
    (pointer) =>
        _native.miracle_config_add_environment_variable(_config._data, pointer),
  );

  @override
  void _removeAt(int index) =>
      _native.miracle_config_remove_environment_variable(_config._data, index);

  void _withVariable(
    EnvironmentVariable variable,
    void Function(Pointer<miracle_environment_variable_t>) body,
  ) {
    _withNativeStrings(<String?>[variable.key, variable.value], (strings) {
      final pointer = calloc<miracle_environment_variable_t>();
      try {
        pointer.ref
          ..key = strings[0]
          ..value = strings[1];
        body(pointer);
      } finally {
        calloc.free(pointer);
      }
    });
  }
}

/// The per-workspace settings.
class _WorkspaceConfigs extends _NativeList<WorkspaceConfig> {
  _WorkspaceConfigs._(this._config);

  final MiracleConfig _config;

  @override
  int get length =>
      _native.miracle_config_get_workspace_config_count(_config._data);

  @override
  WorkspaceConfig operator [](int index) {
    _checkIndex(index, length);
    final workspace = _native.miracle_config_get_workspace_config(
      _config._data,
      index,
    );
    return WorkspaceConfig(
      number: workspace.has_num ? workspace.num : null,
      name: workspace.has_name ? _toDartString(workspace.name) : null,
    );
  }

  @override
  void operator []=(int index, WorkspaceConfig value) {
    _checkIndex(index, length);
    _withWorkspace(
      value,
      (pointer) => _native.miracle_config_set_workspace_config(
        _config._data,
        index,
        pointer,
      ),
    );
  }

  @override
  void add(WorkspaceConfig element) => _withWorkspace(
    element,
    (pointer) =>
        _native.miracle_config_add_workspace_config(_config._data, pointer),
  );

  @override
  void _removeAt(int index) =>
      _native.miracle_config_remove_workspace_config(_config._data, index);

  void _withWorkspace(
    WorkspaceConfig workspace,
    void Function(Pointer<miracle_workspace_config_t>) body,
  ) {
    _withNativeString(workspace.name, (name) {
      final pointer = calloc<miracle_workspace_config_t>();
      try {
        pointer.ref
          ..has_num = workspace.number != null
          ..num = workspace.number ?? 0
          ..has_name = workspace.name != null
          ..name = name;
        body(pointer);
      } finally {
        calloc.free(pointer);
      }
    });
  }
}

/// The XKB options on the configured keymap.
class _KeymapOptions extends _NativeList<String> {
  _KeymapOptions._(this._config);

  final MiracleConfig _config;

  /// The C library reaches into the keymap without checking that there is one,
  /// so an unset keymap has to be caught here rather than there.
  miracle_keymap_t get _keymap {
    final keymap = _native.miracle_config_get_keymap(_config._data);
    if (!keymap.is_set) {
      throw StateError(
        'No keymap is configured, so it has no options. Call '
        'MiracleConfig.keymap.set() first.',
      );
    }
    return keymap;
  }

  @override
  int get length => _keymap.options_count;

  @override
  String operator [](int index) {
    _checkIndex(index, length);
    return _toDartString(
      _native.miracle_config_get_keymap_option(_config._data, index),
    );
  }

  @override
  void operator []=(int index, String value) {
    _checkIndex(index, length);
    _withNativeString(
      value,
      (string) => _native.miracle_config_set_keymap_option(
        _config._data,
        index,
        string,
      ),
    );
  }

  @override
  void add(String element) {
    _keymap;
    _withNativeString(
      element,
      (string) =>
          _native.miracle_config_add_keymap_option(_config._data, string),
    );
  }

  @override
  void _removeAt(int index) =>
      _native.miracle_config_remove_keymap_option(_config._data, index);
}

/// The animations that make up one [AnimateableEvent].
class _AnimationParts extends _NativeList<BuiltInAnimation> {
  _AnimationParts._(this._config, this._index);

  final MiracleConfig _config;
  final int _index;

  T _withEvent<T>(T Function(Pointer<miracle_animateable_event_t>) body) {
    final pointer = calloc<miracle_animateable_event_t>();
    try {
      pointer.ref = _native.miracle_config_get_animateable_event(
        _config._data,
        _index,
      );
      return body(pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// Builds a by-value animation struct for the C functions that take one.
  T _withAnimation<T>(
    BuiltInAnimation animation,
    T Function(miracle_built_in_animation_t) body,
  ) {
    final pointer = calloc<miracle_built_in_animation_t>();
    try {
      pointer.ref
        ..type = animation.type.value
        ..function = animation.function.value
        ..c1 = animation.c1
        ..c2 = animation.c2
        ..c3 = animation.c3
        ..c4 = animation.c4
        ..c5 = animation.c5
        ..n1 = animation.n1
        ..d1 = animation.d1;
      return body(pointer.ref);
    } finally {
      calloc.free(pointer);
    }
  }

  @override
  int get length => _withEvent((pointer) => pointer.ref.num_parts);

  @override
  BuiltInAnimation operator [](int index) {
    _checkIndex(index, length);
    return _withEvent((pointer) {
      final part = _native.miracle_animateable_event_get_animation_part(
        pointer,
        index,
      );
      return BuiltInAnimation(
        type: AnimationType.fromValue(part.type) ?? AnimationType.disabled,
        function: EaseFunction.fromValue(part.function) ?? EaseFunction.linear,
        c1: part.c1,
        c2: part.c2,
        c3: part.c3,
        c4: part.c4,
        c5: part.c5,
        n1: part.n1,
        d1: part.d1,
      );
    });
  }

  @override
  void operator []=(int index, BuiltInAnimation value) {
    _checkIndex(index, length);
    _withEvent(
      (pointer) => _withAnimation(
        value,
        (animation) => _native.miracle_animateable_event_set_animation(
          pointer,
          index,
          animation,
        ),
      ),
    );
  }

  @override
  void add(BuiltInAnimation element) => _withEvent(
    (pointer) => _withAnimation(
      element,
      (animation) =>
          _native.miracle_animateable_event_add_animation(pointer, animation),
    ),
  );

  @override
  void _removeAt(int index) => _withEvent(
    (pointer) =>
        _native.miracle_animateable_event_remove_animation(pointer, index),
  );
}

/// The events miracle can animate.
///
/// Miracle defines a fixed set of these, so the list cannot grow or shrink.
class _AnimateableEvents extends _NativeList<AnimateableEvent> {
  _AnimateableEvents._(this._config);

  final MiracleConfig _config;

  @override
  int get length {
    _config._data;
    return _native.miracle_config_get_animateable_event_count();
  }

  @override
  AnimateableEvent operator [](int index) {
    _checkIndex(index, length);
    return AnimateableEvent._(_config, index);
  }

  @override
  void operator []=(int index, AnimateableEvent value) =>
      throw UnsupportedError(_fixed);

  @override
  set length(int newLength) => throw UnsupportedError(_fixed);

  @override
  void add(AnimateableEvent element) => throw UnsupportedError(_fixed);

  @override
  void insert(int index, AnimateableEvent element) =>
      throw UnsupportedError(_fixed);

  @override
  void _removeAt(int index) => throw UnsupportedError(_fixed);

  static const String _fixed =
      'Miracle defines a fixed set of animateable events; this list cannot '
      'be resized or reassigned. Mutate the events themselves instead.';
}

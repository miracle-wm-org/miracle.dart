part of 'miracle_config.dart';

/// Reads a `float[4]` colour, which the C library orders as RGBA.
RgbaColor _readColor(Array<Float> array) =>
    RgbaColor(red: array[0], green: array[1], blue: array[2], alpha: array[3]);

/// Writes a colour into a `float[4]`.
void _writeColor(Array<Float> array, RgbaColor color) {
  array[0] = color.red;
  array[1] = color.green;
  array[2] = color.blue;
  array[3] = color.alpha;
}

/// The border drawn around windows.
///
/// This is a live view: assigning to a property writes straight through to the
/// configuration that [MiracleConfig] holds.
class BorderConfig {
  BorderConfig._(this._config);

  final MiracleConfig _config;

  miracle_border_config_t get _read =>
      _native.miracle_config_get_border_config(_config._data);

  void _update(void Function(miracle_border_config_t) mutate) {
    final pointer = calloc<miracle_border_config_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_border_config(_config._data, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// The border's thickness, in pixels.
  int get size => _read.size;
  set size(int value) => _update((border) => border.size = value);

  /// The radius of the border's rounded corners, in pixels.
  double get radius => _read.radius;
  set radius(double value) => _update((border) => border.radius = value);

  /// The border colour of the focused window.
  RgbaColor get focusColor => _readColor(_read.focus_color);
  set focusColor(RgbaColor value) =>
      _update((border) => _writeColor(border.focus_color, value));

  /// The border colour of unfocused windows.
  RgbaColor get color => _readColor(_read.color);
  set color(RgbaColor value) =>
      _update((border) => _writeColor(border.color, value));

  @override
  String toString() =>
      'BorderConfig(size: $size, radius: $radius, '
      'focusColor: $focusColor, color: $color)';
}

/// Dragging windows with the pointer.
class DragAndDrop {
  DragAndDrop._(this._config);

  final MiracleConfig _config;

  miracle_drag_and_drop_config_t get _read =>
      _native.miracle_config_get_drag_and_drop(_config._data);

  void _update(void Function(miracle_drag_and_drop_config_t) mutate) {
    final pointer = calloc<miracle_drag_and_drop_config_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_drag_and_drop(_config._data, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// Whether windows can be dragged.
  bool get enabled => _read.enabled;
  set enabled(bool value) => _update((config) => config.enabled = value);

  /// The modifiers that must be held to start a drag.
  Set<Modifier> get modifiers => _unpackModifiers(_read.modifiers);
  set modifiers(Set<Modifier> value) =>
      _update((config) => config.modifiers = _packModifiers(value));

  @override
  String toString() => 'DragAndDrop(enabled: $enabled, modifiers: $modifiers)';
}

/// Pointer device settings.
class MouseConfig {
  MouseConfig._(this._config);

  final MiracleConfig _config;

  miracle_mouse_config_t get _read =>
      _native.miracle_config_get_mouse_config(_config._data);

  void _update(void Function(miracle_mouse_config_t) mutate) {
    final pointer = calloc<miracle_mouse_config_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_mouse_config(_config._data, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// Which hand the pointer is set up for.
  Handedness get handedness =>
      Handedness.fromValue(_read.handedness) ?? Handedness.right;
  set handedness(Handedness value) =>
      _update((config) => config.handedness = value.value);

  /// How strongly pointer movement is accelerated, from -1.0 to 1.0.
  double get accelerationBias => _read.acceleration_bias;
  set accelerationBias(double value) =>
      _update((config) => config.acceleration_bias = value);

  /// The vertical scroll speed multiplier.
  double get vscrollSpeed => _read.vscroll_speed;
  set vscrollSpeed(double value) =>
      _update((config) => config.vscroll_speed = value);

  /// The horizontal scroll speed multiplier.
  double get hscrollSpeed => _read.hscroll_speed;
  set hscrollSpeed(double value) =>
      _update((config) => config.hscroll_speed = value);

  /// How pointer movement is filtered.
  Acceleration get acceleration =>
      Acceleration.fromValue(_read.acceleration) ?? Acceleration.none;
  set acceleration(Acceleration value) =>
      _update((config) => config.acceleration = value.value);

  @override
  String toString() =>
      'MouseConfig(handedness: ${handedness.wireName}, '
      'accelerationBias: $accelerationBias, '
      'acceleration: ${acceleration.wireName})';
}

/// Touchpad settings.
class TouchpadConfig {
  TouchpadConfig._(this._config);

  final MiracleConfig _config;

  miracle_touchpad_config_t get _read =>
      _native.miracle_config_get_touchpad_config(_config._data);

  void _update(void Function(miracle_touchpad_config_t) mutate) {
    final pointer = calloc<miracle_touchpad_config_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_touchpad_config(_config._data, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// Whether the touchpad is ignored while the keyboard is in use.
  bool get disableWhileTyping => _read.disable_while_typing;
  set disableWhileTyping(bool value) =>
      _update((config) => config.disable_while_typing = value);

  /// Whether the touchpad is ignored while a mouse is plugged in.
  bool get disableWithExternalMouse => _read.disable_with_external_mouse;
  set disableWithExternalMouse(bool value) =>
      _update((config) => config.disable_with_external_mouse = value);

  /// How strongly pointer movement is accelerated, from -1.0 to 1.0.
  double get accelerationBias => _read.acceleration_bias;
  set accelerationBias(double value) =>
      _update((config) => config.acceleration_bias = value);

  /// The vertical scroll speed multiplier.
  double get vscrollSpeed => _read.vscroll_speed;
  set vscrollSpeed(double value) =>
      _update((config) => config.vscroll_speed = value);

  /// The horizontal scroll speed multiplier.
  double get hscrollSpeed => _read.hscroll_speed;
  set hscrollSpeed(double value) =>
      _update((config) => config.hscroll_speed = value);

  /// Whether tapping the touchpad counts as a click.
  bool get tapToClick => _read.tap_to_click;
  set tapToClick(bool value) =>
      _update((config) => config.tap_to_click = value);

  /// Whether pressing both buttons together counts as a middle click.
  bool get middleMouseButtonEmulation => _read.middle_mouse_button_emulation;
  set middleMouseButtonEmulation(bool value) =>
      _update((config) => config.middle_mouse_button_emulation = value);

  /// How the touchpad generates button events.
  TouchpadClickMode get clickMode =>
      TouchpadClickMode.fromValue(_read.click_mode) ?? TouchpadClickMode.none;
  set clickMode(TouchpadClickMode value) =>
      _update((config) => config.click_mode = value.value);

  /// How the touchpad generates scroll events.
  TouchpadScrollMode get scrollMode =>
      TouchpadScrollMode.fromValue(_read.scroll_mode) ??
      TouchpadScrollMode.none;
  set scrollMode(TouchpadScrollMode value) =>
      _update((config) => config.scroll_mode = value.value);

  @override
  String toString() =>
      'TouchpadConfig(tapToClick: $tapToClick, '
      'clickMode: ${clickMode.wireName}, '
      'scrollMode: ${scrollMode.wireName})';
}

/// The keyboard layout miracle applies.
///
/// A keymap is either set or unset; when it is unset, miracle uses the system
/// default. [options] can only be touched while [isSet] is true — the C library
/// dereferences the keymap without checking, so reaching into the options of an
/// unset keymap would abort the process rather than throw.
class Keymap {
  Keymap._(this._config);

  final MiracleConfig _config;

  miracle_keymap_t get _read =>
      _native.miracle_config_get_keymap(_config._data);

  /// Whether a keymap is configured at all.
  bool get isSet => _read.is_set;

  /// The layout's language, e.g. `us`.
  ///
  /// Empty when [isSet] is false.
  String get language => _toDartString(_read.language);
  set language(String value) => _write(isSet: true, language: value);

  /// The layout's variant, e.g. `dvorak`, or `null` when there is none.
  String? get variant {
    final keymap = _read;
    return keymap.has_variant ? _toDartString(keymap.variant) : null;
  }

  set variant(String? value) =>
      _write(isSet: true, variant: value, clearVariant: value == null);

  /// The XKB options applied on top of the layout.
  ///
  /// Throws a [StateError] if [isSet] is false.
  List<String> get options => _KeymapOptions._(_config);

  /// Sets the layout, replacing whatever was configured before.
  ///
  /// Any [options] configured previously are dropped, because the C library
  /// rebuilds the keymap from scratch when one was not already set.
  void set({required String language, String? variant}) => _write(
    isSet: true,
    language: language,
    variant: variant,
    clearVariant: variant == null,
  );

  /// Unsets the keymap, leaving miracle to use the system default.
  void clear() => _write(isSet: false);

  void _write({
    bool? isSet,
    String? language,
    String? variant,
    bool clearVariant = false,
  }) {
    // Read everything into Dart first: the struct the getter hands back points
    // into the configuration's own strings, and feeding those pointers back to
    // the setter would have it assign a string from itself.
    final current = _read;
    final wantSet = isSet ?? current.is_set;
    final wantLanguage = language ?? _toDartString(current.language);
    final wantVariant =
        clearVariant
            ? null
            : variant ??
                (current.has_variant ? _toDartString(current.variant) : null);
    final optionsCount = current.options_count;

    _withNativeStrings(<String?>[wantLanguage, wantVariant], (strings) {
      final pointer = calloc<miracle_keymap_t>();
      try {
        pointer.ref
          ..is_set = wantSet
          ..language = strings[0]
          ..has_variant = wantVariant != null
          ..variant = strings[1]
          ..options_count = optionsCount;
        _native.miracle_config_set_keymap(_config._data, pointer);
      } finally {
        calloc.free(pointer);
      }
    });
  }

  @override
  String toString() =>
      'Keymap(isSet: $isSet, language: $language, '
      'variant: $variant)';
}

/// The pointer cursor.
class Cursor {
  Cursor._(this._config);

  final MiracleConfig _config;

  miracle_cursor_t get _read =>
      _native.miracle_config_get_cursor(_config._data);

  void _update(void Function(miracle_cursor_t) mutate) {
    final pointer = calloc<miracle_cursor_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_cursor(_config._data, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// How large the cursor is drawn, as a multiple of its natural size.
  double get scale => _read.scale;
  set scale(double value) => _update((cursor) => cursor.scale = value);

  /// Whether the cursor focuses windows by hovering or by clicking.
  CursorFocusMode get focusMode =>
      CursorFocusMode.fromValue(_read.focus_mode) ?? CursorFocusMode.hover;
  set focusMode(CursorFocusMode value) =>
      _update((cursor) => cursor.focus_mode = value.value);

  @override
  String toString() =>
      'Cursor(scale: $scale, focusMode: ${focusMode.wireName})';
}

/// The screen magnifier.
class Magnifier {
  Magnifier._(this._config);

  final MiracleConfig _config;

  miracle_magnifier_t get _read =>
      _native.miracle_config_get_magnifier(_config._data);

  void _update(void Function(miracle_magnifier_t) mutate) {
    final pointer = calloc<miracle_magnifier_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      // Unlike its siblings, this setter takes the struct by value.
      _native.miracle_config_set_magnifier(_config._data, pointer.ref);
    } finally {
      calloc.free(pointer);
    }
  }

  /// Whether the magnifier can be shown.
  bool get enabled => _read.enabled;
  set enabled(bool value) => _update((magnifier) => magnifier.enabled = value);

  /// How much the magnifier zooms in.
  double get scale => _read.scale;
  set scale(double value) => _update((magnifier) => magnifier.scale = value);

  /// How much a zoom keybinding changes [scale] by.
  double get scaleIncrement => _read.scale_increment;
  set scaleIncrement(double value) =>
      _update((magnifier) => magnifier.scale_increment = value);

  /// The magnifier's width, in pixels.
  int get width => _read.width;
  set width(int value) => _update((magnifier) => magnifier.width = value);

  /// The magnifier's height, in pixels.
  int get height => _read.height;
  set height(int value) => _update((magnifier) => magnifier.height = value);

  /// How much a resize keybinding changes [width] and [height] by.
  int get sizeIncrement => _read.size_increment;
  set sizeIncrement(int value) =>
      _update((magnifier) => magnifier.size_increment = value);

  @override
  String toString() =>
      'Magnifier(enabled: $enabled, scale: $scale, '
      'width: $width, height: $height)';
}

/// Clicking by resting the pointer still.
class HoverClick {
  HoverClick._(this._config);

  final MiracleConfig _config;

  miracle_hover_click_t get _read =>
      _native.miracle_config_get_hover_click(_config._data);

  void _update(void Function(miracle_hover_click_t) mutate) {
    final pointer = calloc<miracle_hover_click_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_hover_click(_config._data, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// Whether resting the pointer clicks.
  bool get enabled => _read.enabled;
  set enabled(bool value) => _update((click) => click.enabled = value);

  /// How long the pointer must rest before it clicks.
  Duration get hoverDuration =>
      Duration(milliseconds: _read.hover_duration_milliseconds);
  set hoverDuration(Duration value) => _update(
    (click) => click.hover_duration_milliseconds = value.inMilliseconds,
  );

  /// How far the pointer may drift before the pending click is cancelled.
  int get cancelDisplacementThreshold => _read.cancel_displacement_threshold;
  set cancelDisplacementThreshold(int value) =>
      _update((click) => click.cancel_displacement_threshold = value);

  /// How far the pointer must move before it will click again.
  int get reclickDisplacementThreshold => _read.reclick_displacement_threshold;
  set reclickDisplacementThreshold(int value) =>
      _update((click) => click.reclick_displacement_threshold = value);

  @override
  String toString() =>
      'HoverClick(enabled: $enabled, hoverDuration: $hoverDuration)';
}

/// Right-clicking by holding the primary button down.
class SimulatedSecondaryClick {
  SimulatedSecondaryClick._(this._config);

  final MiracleConfig _config;

  miracle_simulated_secondary_click_t get _read =>
      _native.miracle_config_get_simulated_secondary_click(_config._data);

  void _update(void Function(miracle_simulated_secondary_click_t) mutate) {
    final pointer = calloc<miracle_simulated_secondary_click_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_simulated_secondary_click(
        _config._data,
        pointer,
      );
    } finally {
      calloc.free(pointer);
    }
  }

  /// Whether holding the primary button right-clicks.
  bool get enabled => _read.enabled;
  set enabled(bool value) => _update((click) => click.enabled = value);

  /// How long the button must be held.
  Duration get holdDuration =>
      Duration(milliseconds: _read.hold_duration_milliseconds);
  set holdDuration(Duration value) => _update(
    (click) => click.hold_duration_milliseconds = value.inMilliseconds,
  );

  /// How far the pointer may drift before the pending click is cancelled.
  int get displacementThreshold => _read.displacement_threshold;
  set displacementThreshold(int value) =>
      _update((click) => click.displacement_threshold = value);

  @override
  String toString() =>
      'SimulatedSecondaryClick(enabled: $enabled, '
      'holdDuration: $holdDuration)';
}

/// Ignoring keys that are not held down long enough.
class SlowKeys {
  SlowKeys._(this._config);

  final MiracleConfig _config;

  miracle_slow_keys_t get _read =>
      _native.miracle_config_get_slow_keys(_config._data);

  void _update(void Function(miracle_slow_keys_t) mutate) {
    final pointer = calloc<miracle_slow_keys_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_slow_keys(_config._data, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// Whether slow keys are active.
  bool get enabled => _read.enabled;
  set enabled(bool value) => _update((keys) => keys.enabled = value);

  /// How long a key must be held before it registers.
  Duration get holdDuration =>
      Duration(milliseconds: _read.hold_duration_milliseconds);
  set holdDuration(Duration value) =>
      _update((keys) => keys.hold_duration_milliseconds = value.inMilliseconds);

  @override
  String toString() =>
      'SlowKeys(enabled: $enabled, holdDuration: $holdDuration)';
}

/// Latching modifiers so they need not be held.
class StickyKeys {
  StickyKeys._(this._config);

  final MiracleConfig _config;

  miracle_sticky_keys_t get _read =>
      _native.miracle_config_get_sticky_keys(_config._data);

  void _update(void Function(miracle_sticky_keys_t) mutate) {
    final pointer = calloc<miracle_sticky_keys_t>();
    try {
      pointer.ref = _read;
      mutate(pointer.ref);
      _native.miracle_config_set_sticky_keys(_config._data, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// Whether sticky keys are active.
  bool get enabled => _read.enabled;
  set enabled(bool value) => _update((keys) => keys.enabled = value);

  /// Whether pressing two keys at once turns sticky keys off again.
  bool get disableIfTwoKeysArePressedTogether =>
      _read.should_disable_if_two_keys_are_pressed_together;
  set disableIfTwoKeysArePressedTogether(bool value) => _update(
    (keys) => keys.should_disable_if_two_keys_are_pressed_together = value,
  );

  @override
  String toString() =>
      'StickyKeys(enabled: $enabled, '
      'disableIfTwoKeysArePressedTogether: '
      '$disableIfTwoKeysArePressedTogether)';
}

/// A shader applied to the whole output.
class OutputFilter {
  OutputFilter._(this._config);

  final MiracleConfig _config;

  miracle_output_filter_t get _read =>
      _native.miracle_config_get_output_filter(_config._data);

  /// The shader to run over the output, or `null` when there is none.
  String? get shaderPath {
    final filter = _read;
    return filter.shader_path_enabled
        ? _toDartString(filter.shader_path)
        : null;
  }

  set shaderPath(String? value) {
    _withNativeString(value, (string) {
      final pointer = calloc<miracle_output_filter_t>();
      try {
        pointer.ref
          ..shader_path_enabled = value != null
          ..shader_path = string;
        _native.miracle_config_set_output_filter(_config._data, pointer);
      } finally {
        calloc.free(pointer);
      }
    });
  }

  @override
  String toString() => 'OutputFilter(shaderPath: $shaderPath)';
}

/// An event miracle can animate, such as a window opening.
///
/// The set of animateable events is fixed by miracle; [MiracleConfig
/// .animateableEvents] lists them all. Each event runs [parts] concurrently
/// over [durationSeconds].
class AnimateableEvent {
  AnimateableEvent._(this._config, this.index);

  final MiracleConfig _config;

  /// This event's position in [MiracleConfig.animateableEvents].
  final int index;

  miracle_animateable_event_t get _read =>
      _native.miracle_config_get_animateable_event(_config._data, index);

  /// Runs [body] with the event in native memory, so the C functions that take
  /// a pointer to it can be called.
  ///
  /// The struct is re-read every time rather than cached, because its
  /// `num_parts` goes stale as soon as an animation is added or removed.
  T _withEvent<T>(T Function(Pointer<miracle_animateable_event_t>) body) {
    final pointer = calloc<miracle_animateable_event_t>();
    try {
      pointer.ref = _read;
      return body(pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  /// The event's name, e.g. `window_open`. Fixed by miracle.
  String get name => _toDartString(_read.name);

  /// Whether this event still has miracle's default animation.
  bool get isDefault => _read.is_default;

  /// How long the whole event takes.
  double get durationSeconds => _read.duration_seconds;

  set durationSeconds(double value) {
    _withEvent((pointer) {
      pointer.ref.duration_seconds = value;
      _native.miracle_config_set_animateable_event(
        _config._data,
        index,
        pointer,
      );
    });
  }

  /// The animations that run concurrently when this event happens.
  List<BuiltInAnimation> get parts => _AnimationParts._(_config, index);

  /// Restores miracle's default animation for this event.
  void reset() =>
      _native.miracle_config_reset_animation_definition(_config._data, index);

  @override
  String toString() =>
      'AnimateableEvent(name: $name, '
      'durationSeconds: $durationSeconds, isDefault: $isDefault)';
}

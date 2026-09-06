part of 'miracle_config.dart';

/// A keyboard modifier.
///
/// The values are Mir's input event modifier bits, so they combine into a
/// bitmask. [primary] is miracle's own sentinel meaning "whatever the user
/// configured as [MiracleConfig.primaryModifier]".
///
/// See also:
///
///  * [MiracleConfig.primaryModifier], the modifier [primary] stands in for.
///  * [CustomKeyCommand.modifiers], which takes a set of these.
enum Modifier {
  alt('alt', 2),
  altLeft('alt_left', 4),
  altRight('alt_right', 8),
  shift('shift', 16),
  shiftLeft('shift_left', 32),
  shiftRight('shift_right', 64),
  sym('sym', 128),
  function('function', 256),
  ctrl('ctrl', 512),
  ctrlLeft('ctrl_left', 1024),
  ctrlRight('ctrl_right', 2048),
  meta('meta', 4096),
  metaLeft('meta_left', 8192),
  metaRight('meta_right', 16384),
  capsLock('caps_lock', 32768),
  numLock('num_lock', 65536),
  scrollLock('scroll_lock', 131072),
  primary('primary', 262144);

  const Modifier(this.wireName, this.value);

  /// The name used in miracle's configuration file, e.g. `alt_left`.
  final String wireName;

  /// The bit this modifier occupies in a modifier mask.
  final int value;

  /// The modifier named [value], or `null` if there is no such modifier.
  static Modifier? fromString(String value) {
    for (final modifier in values) {
      if (modifier.wireName == value) return modifier;
    }
    return null;
  }

  /// The modifier with the bit [value], or `null` if there is no such modifier.
  static Modifier? fromValue(int value) {
    for (final modifier in values) {
      if (modifier.value == value) return modifier;
    }
    return null;
  }
}

/// A mouse button.
enum MouseButton {
  primary('primary', 1),
  secondary('secondary', 2),
  tertiary('tertiary', 4),
  back('back', 8),
  forward('forward', 16),
  side('side', 32),
  extra('extra', 64),
  task('task', 128);

  const MouseButton(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this button.
  final int value;

  /// The button named [value], or `null` if there is no such button.
  static MouseButton? fromString(String value) {
    for (final button in values) {
      if (button.wireName == value) return button;
    }
    return null;
  }

  /// The button with [value], or `null` if there is no such button.
  static MouseButton? fromValue(int value) {
    for (final button in values) {
      if (button.value == value) return button;
    }
    return null;
  }
}

/// The pointer action a mouse binding fires on.
enum PointerAction {
  up('up', 0),
  down('down', 1),
  enter('enter', 2),
  leave('leave', 3),
  motion('motion', 4);

  const PointerAction(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this action.
  final int value;

  /// The action named [value], or `null` if there is no such action.
  static PointerAction? fromString(String value) {
    for (final action in values) {
      if (action.wireName == value) return action;
    }
    return null;
  }

  /// The action with [value], or `null` if there is no such action.
  static PointerAction? fromValue(int value) {
    for (final action in values) {
      if (action.value == value) return action;
    }
    return null;
  }
}

/// The keyboard action a key binding fires on.
///
/// The C library silently ignores key commands whose action is not one of
/// these, which is why [CustomKeyCommand.action] is typed rather than an `int`.
enum KeyboardAction {
  up('up', 0),
  down('down', 1),
  repeat('repeat', 2);

  const KeyboardAction(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this action.
  final int value;

  /// The action named [value], or `null` if there is no such action.
  static KeyboardAction? fromString(String value) {
    for (final action in values) {
      if (action.wireName == value) return action;
    }
    return null;
  }

  /// The action with [value], or `null` if there is no such action.
  static KeyboardAction? fromValue(int value) {
    for (final action in values) {
      if (action.value == value) return action;
    }
    return null;
  }
}

/// One of miracle's built-in commands, as bound by a [KeyCommandOverride].
enum BuiltInKeyCommand {
  terminal('terminal', 0),
  requestVerticalLayout('request_vertical_layout', 1),
  requestHorizontalLayout('request_horizontal_layout', 2),
  toggleResize('toggle_resize', 3),
  resizeUp('resize_up', 4),
  resizeDown('resize_down', 5),
  resizeLeft('resize_left', 6),
  resizeRight('resize_right', 7),
  moveUp('move_up', 8),
  moveDown('move_down', 9),
  moveLeft('move_left', 10),
  moveRight('move_right', 11),
  selectUp('select_up', 12),
  selectDown('select_down', 13),
  selectLeft('select_left', 14),
  selectRight('select_right', 15),
  quitActiveWindow('quit_active_window', 16),
  quitCompositor('quit_compositor', 17),
  fullscreen('fullscreen', 18),
  selectWorkspace1('select_workspace_1', 19),
  selectWorkspace2('select_workspace_2', 20),
  selectWorkspace3('select_workspace_3', 21),
  selectWorkspace4('select_workspace_4', 22),
  selectWorkspace5('select_workspace_5', 23),
  selectWorkspace6('select_workspace_6', 24),
  selectWorkspace7('select_workspace_7', 25),
  selectWorkspace8('select_workspace_8', 26),
  selectWorkspace9('select_workspace_9', 27),
  selectWorkspace0('select_workspace_0', 28),
  moveToWorkspace1('move_to_workspace_1', 29),
  moveToWorkspace2('move_to_workspace_2', 30),
  moveToWorkspace3('move_to_workspace_3', 31),
  moveToWorkspace4('move_to_workspace_4', 32),
  moveToWorkspace5('move_to_workspace_5', 33),
  moveToWorkspace6('move_to_workspace_6', 34),
  moveToWorkspace7('move_to_workspace_7', 35),
  moveToWorkspace8('move_to_workspace_8', 36),
  moveToWorkspace9('move_to_workspace_9', 37),
  moveToWorkspace0('move_to_workspace_0', 38),
  toggleFloating('toggle_floating', 39),
  togglePinnedToWorkspace('toggle_pinned_to_workspace', 40),
  toggleTabbing('toggle_tabbing', 41),
  toggleStacking('toggle_stacking', 42),
  magnifierOn('magnifier_on', 43),
  magnifierOff('magnifier_off', 44),
  magnifierIncreaseSize('magnifier_increase_size', 45),
  magnifierDecreaseSize('magnifier_decrease_size', 46),
  magnifierIncreaseScale('magnifier_increase_scale', 47),
  magnifierDecreaseScale('magnifier_decrease_scale', 48),
  reloadConfig('reload_config', 49);

  const BuiltInKeyCommand(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this command.
  final int value;

  /// The command named [value], or `null` if there is no such command.
  static BuiltInKeyCommand? fromString(String value) {
    for (final command in values) {
      if (command.wireName == value) return command;
    }
    return null;
  }

  /// The command with [value], or `null` if there is no such command.
  static BuiltInKeyCommand? fromValue(int value) {
    for (final command in values) {
      if (command.value == value) return command;
    }
    return null;
  }
}

/// The kind of movement a [BuiltInAnimation] applies.
enum AnimationType {
  disabled('disabled', 0),
  slide('slide', 1),
  grow('grow', 2),
  shrink('shrink', 3),
  fade('fade', 4);

  const AnimationType(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this type.
  final int value;

  /// The type named [value], or `null` if there is no such type.
  static AnimationType? fromString(String value) {
    for (final type in values) {
      if (type.wireName == value) return type;
    }
    return null;
  }

  /// The type with [value], or `null` if there is no such type.
  static AnimationType? fromValue(int value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// The easing curve a [BuiltInAnimation] follows.
///
/// See <https://easings.net/> for what each curve looks like, and for the
/// meaning of the `c1`..`d1` coefficients on [BuiltInAnimation].
enum EaseFunction {
  linear('linear', 0),
  easeInSine('ease_in_sine', 1),
  easeOutSine('ease_out_sine', 2),
  easeInOutSine('ease_in_out_sine', 3),
  easeInQuad('ease_in_quad', 4),
  easeOutQuad('ease_out_quad', 5),
  easeInOutQuad('ease_in_out_quad', 6),
  easeInCubic('ease_in_cubic', 7),
  easeOutCubic('ease_out_cubic', 8),
  easeInOutCubic('ease_in_out_cubic', 9),
  easeInQuart('ease_in_quart', 10),
  easeOutQuart('ease_out_quart', 11),
  easeInOutQuart('ease_in_out_quart', 12),
  easeInQuint('ease_in_quint', 13),
  easeOutQuint('ease_out_quint', 14),
  easeInOutQuint('ease_in_out_quint', 15),
  easeInExpo('ease_in_expo', 16),
  easeOutExpo('ease_out_expo', 17),
  easeInOutExpo('ease_in_out_expo', 18),
  easeInCirc('ease_in_circ', 19),
  easeOutCirc('ease_out_circ', 20),
  easeInOutCirc('ease_in_out_circ', 21),
  easeInBack('ease_in_back', 22),
  easeOutBack('ease_out_back', 23),
  easeInOutBack('ease_in_out_back', 24),
  easeInElastic('ease_in_elastic', 25),
  easeOutElastic('ease_out_elastic', 26),
  easeInOutElastic('ease_in_out_elastic', 27),
  easeInBounce('ease_in_bounce', 28),
  easeOutBounce('ease_out_bounce', 29),
  easeInOutBounce('ease_in_out_bounce', 30);

  const EaseFunction(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this function.
  final int value;

  /// The function named [value], or `null` if there is no such function.
  static EaseFunction? fromString(String value) {
    for (final function in values) {
      if (function.wireName == value) return function;
    }
    return null;
  }

  /// The function with [value], or `null` if there is no such function.
  static EaseFunction? fromValue(int value) {
    for (final function in values) {
      if (function.value == value) return function;
    }
    return null;
  }
}

/// Which window the cursor gives focus to.
enum CursorFocusMode {
  hover('hover', 0),
  click('click', 1);

  const CursorFocusMode(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this mode.
  final int value;

  /// The mode named [value], or `null` if there is no such mode.
  static CursorFocusMode? fromString(String value) {
    for (final mode in values) {
      if (mode.wireName == value) return mode;
    }
    return null;
  }

  /// The mode with [value], or `null` if there is no such mode.
  static CursorFocusMode? fromValue(int value) {
    for (final mode in values) {
      if (mode.value == value) return mode;
    }
    return null;
  }
}

/// Which hand the pointer is configured for.
enum Handedness {
  right('right', 0),
  left('left', 1);

  const Handedness(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this handedness.
  final int value;

  /// The handedness named [value], or `null` if there is no such value.
  static Handedness? fromString(String value) {
    for (final handedness in values) {
      if (handedness.wireName == value) return handedness;
    }
    return null;
  }

  /// The handedness with [value], or `null` if there is no such value.
  static Handedness? fromValue(int value) {
    for (final handedness in values) {
      if (handedness.value == value) return handedness;
    }
    return null;
  }
}

/// How pointer movement is filtered.
///
/// These are Mir's `MirPointerAcceleration` values, which start at 1. The C
/// library's option table also reports a spurious entry at index 0 that
/// duplicates [none]; it is not a distinct acceleration profile and has no
/// member here.
enum Acceleration {
  none('none', 1),

  /// Note the spelling: `adapative` is how the C library spells it, and
  /// [wireName] is faithful to the library rather than to the dictionary.
  adaptive('adapative', 2);

  const Acceleration(this.wireName, this.value);

  /// The name the C library uses for this profile.
  final String wireName;

  /// The value the C library uses for this profile.
  final int value;

  /// The profile named [value], or `null` if there is no such profile.
  static Acceleration? fromString(String value) {
    for (final acceleration in values) {
      if (acceleration.wireName == value) return acceleration;
    }
    return null;
  }

  /// The profile with [value], or `null` if there is no such profile.
  static Acceleration? fromValue(int value) {
    for (final acceleration in values) {
      if (acceleration.value == value) return acceleration;
    }
    return null;
  }
}

/// How a touchpad generates pointer button events.
enum TouchpadClickMode {
  none('none', 0),
  areaToClick('area_to_click', 1),
  fingerCount('finger_count', 2);

  const TouchpadClickMode(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this mode.
  final int value;

  /// The mode named [value], or `null` if there is no such mode.
  static TouchpadClickMode? fromString(String value) {
    for (final mode in values) {
      if (mode.wireName == value) return mode;
    }
    return null;
  }

  /// The mode with [value], or `null` if there is no such mode.
  static TouchpadClickMode? fromValue(int value) {
    for (final mode in values) {
      if (mode.value == value) return mode;
    }
    return null;
  }
}

/// How a touchpad generates scroll events.
///
/// Note that [buttonDownScroll] is 4, not 3: these are Mir's bit flags.
enum TouchpadScrollMode {
  none('none', 0),
  twoFingerScroll('two_finger_scroll', 1),
  edgeScroll('edge_scroll', 2),
  buttonDownScroll('button_down_scroll', 4);

  const TouchpadScrollMode(this.wireName, this.value);

  /// The name used in miracle's configuration file.
  final String wireName;

  /// The value the C library uses for this mode.
  final int value;

  /// The mode named [value], or `null` if there is no such mode.
  static TouchpadScrollMode? fromString(String value) {
    for (final mode in values) {
      if (mode.wireName == value) return mode;
    }
    return null;
  }

  /// The mode with [value], or `null` if there is no such mode.
  static TouchpadScrollMode? fromValue(int value) {
    for (final mode in values) {
      if (mode.value == value) return mode;
    }
    return null;
  }
}

/// How serious a [MiracleConfigError] is.
enum MiracleConfigErrorLevel {
  /// The configuration loaded, but something in it was questionable.
  warning('warning', 0),

  /// Something in the configuration could not be understood.
  error('error', 1);

  const MiracleConfigErrorLevel(this.wireName, this.value);

  /// A lowercase name for this level.
  final String wireName;

  /// The value the C library uses for this level.
  final int value;

  /// The level with [value], or `null` if there is no such level.
  static MiracleConfigErrorLevel? fromValue(int value) {
    for (final level in values) {
      if (level.value == value) return level;
    }
    return null;
  }
}

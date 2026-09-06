// Tests that exercise the real `libmiracle-wm-c`.
//
// They are skipped when the library is not installed, which is the case on the
// CI runners; the pure-Dart half of the configuration API is covered by
// `config_enums_test.dart` instead.
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:miracle/miracle.dart';
import 'package:miracle/src/config/bindings.g.dart';
import 'package:test/test.dart';

/// A configuration exercising the fields the tests read back.
const String _config = '''
inner_gaps:
  x: 5
  y: 6
outer_gaps:
  x: 10
  y: 11
resize_jump: 40
startup_apps:
  - command: nm-applet
    restart_on_death: true
environment_variables:
  - key: FOO
    value: bar
''';

/// How far a colour channel may move across a save.
///
/// Colours are written to YAML as 8-bit channels, so a value in the unit range
/// comes back quantised to the nearest 1/255.
const double _channel = 1 / 255;

/// Loads the bindings the same way the library does, for the parity tests.
MiracleConfigBindings _openBindings() {
  for (final name in <String>[
    'libmiracle-wm-c.so.0',
    '/usr/lib/x86_64-linux-gnu/libmiracle-wm-c.so.0',
    'libmiracle-wm-c.so',
  ]) {
    try {
      return MiracleConfigBindings(DynamicLibrary.open(name));
    } on ArgumentError {
      continue;
    }
  }
  throw StateError('libmiracle-wm-c is available but could not be opened.');
}

/// Reads one of the C library's `(name, value)` option tables.
List<(String, int)> _options(
  int Function() count,
  miracle_config_option_t Function(int) option,
) {
  return <(String, int)>[
    for (var i = 0; i < count(); i++)
      (option(i).name.cast<Utf8>().toDartString(), option(i).value),
  ];
}

void main() {
  final skip =
      MiracleConfig.isAvailable ? null : 'libmiracle-wm-c is not installed';

  late Directory directory;
  late MiracleConfig config;

  setUp(() {
    if (!MiracleConfig.isAvailable) return;
    directory = Directory.systemTemp.createTempSync('miracle_config');
    File('${directory.path}/config.yaml').writeAsStringSync(_config);
    config = MiracleConfig.load('${directory.path}/config.yaml');
  });

  tearDown(() {
    if (!MiracleConfig.isAvailable) return;
    config.dispose();
    directory.deleteSync(recursive: true);
  });

  group('loading', () {
    test('reads the values from the file', () {
      expect(config.innerGapsX, 5);
      expect(config.innerGapsY, 6);
      expect(config.outerGapsX, 10);
      expect(config.outerGapsY, 11);
      expect(config.resizeJump, 40);
      expect(config.path, '${directory.path}/config.yaml');
    });

    test('a clean file produces no errors', () {
      expect(config.errors, isEmpty);
      expect(config.hasErrors, isFalse);
    });

    test('reports problems without throwing', () {
      // miracle checks that the configured terminal actually exists.
      final path = '${directory.path}/bad.yaml';
      File(path).writeAsStringSync('terminal: definitely-not-a-terminal\n');

      final bad = MiracleConfig.load(path);
      addTearDown(bad.dispose);

      expect(bad.errors, isNotEmpty);
      expect(bad.hasErrors, isTrue);
      expect(bad.errors.first.message, contains('terminal'));
      expect(bad.errors.first.level, MiracleConfigErrorLevel.error);
    });

    test('defaultConfigPath is absolute', () {
      expect(MiracleConfig.defaultConfigPath, startsWith('/'));
    });
  }, skip: skip);

  group('scalars', () {
    test('round-trip through save and reload', () {
      config
        ..innerGapsX = 1
        ..innerGapsY = 2
        ..outerGapsX = 3
        ..outerGapsY = 4
        ..resizeJump = 55
        ..animationsEnabled = false
        ..workspaceBackAndForth = true
        ..primaryModifier = Modifier.alt
        ..moveModifier = Modifier.shift
        ..backgroundColor = const RgbaColor(red: 0.25, green: 0.5, blue: 0.75);

      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(reloaded.innerGapsX, 1);
      expect(reloaded.innerGapsY, 2);
      expect(reloaded.outerGapsX, 3);
      expect(reloaded.outerGapsY, 4);
      expect(reloaded.resizeJump, 55);
      expect(reloaded.animationsEnabled, isFalse);
      expect(reloaded.workspaceBackAndForth, isTrue);
      expect(reloaded.primaryModifier, Modifier.alt);
      expect(reloaded.moveModifier, Modifier.shift);
      expect(reloaded.backgroundColor.red, closeTo(0.25, _channel));
      expect(reloaded.backgroundColor.green, closeTo(0.5, _channel));
      expect(reloaded.backgroundColor.blue, closeTo(0.75, _channel));
    });

    test('a null terminal round-trips as null', () {
      config.terminal = null;
      expect(config.terminal, isNull);
    });

    // Loading is asserted against the written file rather than by reloading:
    // miracle validates the terminal with system(), which forks a shell and
    // waitpid()s for it. The Dart VM reaps its own children, so that wait can
    // lose the race and report an installed terminal as missing. Reading the
    // value back in is therefore inherently flaky, through no fault of the
    // binding; writing it out is not.
    test('the terminal is set in memory and written out', () {
      config.terminal = 'kitty';
      expect(config.terminal, 'kitty');

      final target = '${directory.path}/terminal.yaml';
      expect(config.save(target).success, isTrue);
      expect(File(target).readAsStringSync(), contains('terminal: kitty'));
    });

    // miracle-wm has no reader or writer for the primary button; it is set by
    // plugins rather than by the configuration file. It still round-trips in
    // memory, which is all this package can offer.
    test('the primary button is in-memory only', () {
      config.primaryButton = MouseButton.tertiary;
      expect(config.primaryButton, MouseButton.tertiary);

      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);
      expect(reloaded.primaryButton, isNot(MouseButton.tertiary));
    });

    // miracle-wm only writes its `keyboard:` block when a keymap is set, so
    // the key repeat settings are dropped on save without one. That is an
    // upstream quirk rather than something this package can paper over, so
    // both halves of it are pinned here.
    test('key repeat is only saved alongside a keymap', () {
      config
        ..keyRepeatDelay = 400
        ..keyRepeatRate = 20;
      expect(config.keyRepeatDelay, 400);
      expect(config.keyRepeatRate, 20);

      final withoutKeymap = _saveAndReload(config, directory);
      addTearDown(withoutKeymap.dispose);
      expect(withoutKeymap.keyRepeatDelay, isNot(400));
      expect(withoutKeymap.keyRepeatRate, isNot(20));

      config.keymap.set(language: 'us');
      final withKeymap = _saveAndReload(config, directory);
      addTearDown(withKeymap.dispose);
      expect(withKeymap.keyRepeatDelay, 400);
      expect(withKeymap.keyRepeatRate, 20);
      expect(withKeymap.keymap.language, 'us');
    });
  }, skip: skip);

  group('struct groups', () {
    test('border round-trips', () {
      config.border
        ..size = 3
        ..radius = 8.0
        ..focusColor = const RgbaColor(red: 1, green: 0, blue: 0)
        ..color = const RgbaColor(red: 0, green: 0, blue: 1, alpha: 0.5);

      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(reloaded.border.size, 3);
      expect(reloaded.border.radius, 8.0);
      expect(reloaded.border.focusColor.red, closeTo(1.0, _channel));
      expect(reloaded.border.color.blue, closeTo(1.0, _channel));
      expect(reloaded.border.color.alpha, closeTo(0.5, _channel));
    });

    test('mouse and touchpad round-trip', () {
      config.mouse
        ..handedness = Handedness.left
        ..acceleration = Acceleration.adaptive
        ..accelerationBias = 0.5
        ..vscrollSpeed = 2.0
        ..hscrollSpeed = 3.0;
      config.touchpad
        ..disableWhileTyping = true
        ..tapToClick = false
        ..clickMode = TouchpadClickMode.fingerCount
        ..scrollMode = TouchpadScrollMode.edgeScroll;

      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(reloaded.mouse.handedness, Handedness.left);
      expect(reloaded.mouse.acceleration, Acceleration.adaptive);
      expect(reloaded.mouse.accelerationBias, closeTo(0.5, 0.001));
      expect(reloaded.mouse.vscrollSpeed, closeTo(2.0, 0.001));
      expect(reloaded.mouse.hscrollSpeed, closeTo(3.0, 0.001));
      expect(reloaded.touchpad.disableWhileTyping, isTrue);
      expect(reloaded.touchpad.tapToClick, isFalse);
      expect(reloaded.touchpad.clickMode, TouchpadClickMode.fingerCount);
      expect(reloaded.touchpad.scrollMode, TouchpadScrollMode.edgeScroll);
    });

    test('cursor, magnifier and drag-and-drop round-trip', () {
      config.cursor
        ..scale = 2.0
        ..focusMode = CursorFocusMode.click;
      config.magnifier
        ..enabled = true
        ..scale = 3.0
        ..scaleIncrement = 0.5
        ..width = 640
        ..height = 480
        ..sizeIncrement = 20;
      config.dragAndDrop
        ..enabled = true
        ..modifiers = <Modifier>{Modifier.meta, Modifier.ctrl};

      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(reloaded.cursor.scale, closeTo(2.0, 0.001));
      expect(reloaded.cursor.focusMode, CursorFocusMode.click);
      expect(reloaded.magnifier.enabled, isTrue);
      expect(reloaded.magnifier.scale, closeTo(3.0, 0.001));
      expect(reloaded.magnifier.width, 640);
      expect(reloaded.magnifier.height, 480);
      expect(reloaded.magnifier.sizeIncrement, 20);
      expect(reloaded.dragAndDrop.enabled, isTrue);
      expect(reloaded.dragAndDrop.modifiers, <Modifier>{
        Modifier.meta,
        Modifier.ctrl,
      });
    });

    test('accessibility settings round-trip', () {
      config.hoverClick
        ..enabled = true
        ..hoverDuration = const Duration(milliseconds: 900)
        ..cancelDisplacementThreshold = 12
        ..reclickDisplacementThreshold = 8;
      config.simulatedSecondaryClick
        ..enabled = true
        ..holdDuration = const Duration(seconds: 1)
        ..displacementThreshold = 15;
      config.slowKeys
        ..enabled = true
        ..holdDuration = const Duration(milliseconds: 120);
      config.stickyKeys
        ..enabled = true
        ..disableIfTwoKeysArePressedTogether = false;

      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(reloaded.hoverClick.enabled, isTrue);
      expect(
        reloaded.hoverClick.hoverDuration,
        const Duration(milliseconds: 900),
      );
      expect(reloaded.hoverClick.cancelDisplacementThreshold, 12);
      expect(reloaded.hoverClick.reclickDisplacementThreshold, 8);
      expect(
        reloaded.simulatedSecondaryClick.holdDuration,
        const Duration(seconds: 1),
      );
      expect(reloaded.simulatedSecondaryClick.displacementThreshold, 15);
      expect(reloaded.slowKeys.enabled, isTrue);
      expect(reloaded.slowKeys.holdDuration, const Duration(milliseconds: 120));
      expect(reloaded.stickyKeys.enabled, isTrue);
      expect(reloaded.stickyKeys.disableIfTwoKeysArePressedTogether, isFalse);
    });

    test('the output filter maps an unset shader to null', () {
      expect(config.outputFilter.shaderPath, isNull);
      config.outputFilter.shaderPath = '/tmp/shader.frag';
      expect(config.outputFilter.shaderPath, '/tmp/shader.frag');
      config.outputFilter.shaderPath = null;
      expect(config.outputFilter.shaderPath, isNull);
    });
  }, skip: skip);

  group('keymap', () {
    test('starts unset and refuses to expose options', () {
      expect(config.keymap.isSet, isFalse);
      expect(() => config.keymap.options.length, throwsStateError);
      expect(() => config.keymap.options.add('caps:escape'), throwsStateError);
    });

    test('set, mutate and clear', () {
      config.keymap.set(language: 'us', variant: 'dvorak');
      expect(config.keymap.isSet, isTrue);
      expect(config.keymap.language, 'us');
      expect(config.keymap.variant, 'dvorak');

      config.keymap.options
        ..add('caps:escape')
        ..add('grp:alt_shift_toggle');
      expect(config.keymap.options, <String>[
        'caps:escape',
        'grp:alt_shift_toggle',
      ]);

      config.keymap.options[0] = 'caps:swapescape';
      expect(config.keymap.options.first, 'caps:swapescape');
      expect(config.keymap.options.removeAt(1), 'grp:alt_shift_toggle');
      expect(config.keymap.options, <String>['caps:swapescape']);

      config.keymap.variant = null;
      expect(config.keymap.variant, isNull);
      expect(config.keymap.language, 'us');

      config.keymap.clear();
      expect(config.keymap.isSet, isFalse);
    });
  }, skip: skip);

  group('collections', () {
    test('includes insert at an index', () {
      config.includes
        ..add('/a')
        ..add('/c');
      config.includes.insert(1, '/b');
      expect(config.includes, <String>['/a', '/b', '/c']);

      config.includes[2] = '/z';
      expect(config.includes.last, '/z');
      expect(config.includes.removeAt(0), '/a');
      config.includes.clear();
      expect(config.includes, isEmpty);
    });

    test('startup apps round-trip', () {
      config.startupApps.add(
        const StartupApp(command: 'waybar', inSystemdScope: true),
      );
      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(
        reloaded.startupApps.map((app) => app.command),
        containsAll(<String>['nm-applet', 'waybar']),
      );
      final waybar = reloaded.startupApps.firstWhere(
        (app) => app.command == 'waybar',
      );
      expect(waybar.inSystemdScope, isTrue);
    });

    test('environment variables round-trip', () {
      config.environmentVariables.add(
        const EnvironmentVariable(key: 'A', value: 'B'),
      );
      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(
        reloaded.environmentVariables,
        containsAll(<EnvironmentVariable>[
          const EnvironmentVariable(key: 'FOO', value: 'bar'),
          const EnvironmentVariable(key: 'A', value: 'B'),
        ]),
      );
    });

    test('workspace configs round-trip', () {
      config.workspaceConfigs.add(
        const WorkspaceConfig(number: 3, name: 'code'),
      );
      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(
        reloaded.workspaceConfigs.single,
        const WorkspaceConfig(number: 3, name: 'code'),
      );
    });

    test('key commands round-trip', () {
      config.customKeyCommands.add(
        const CustomKeyCommand(
          key: 33,
          command: 'echo hello',
          modifiers: <Modifier>{Modifier.meta},
        ),
      );
      config.builtInKeyCommandOverrides.add(
        const KeyCommandOverride(
          key: 33,
          command: BuiltInKeyCommand.fullscreen,
          modifiers: <Modifier>{Modifier.meta, Modifier.shift},
        ),
      );

      final reloaded = _saveAndReload(config, directory);
      addTearDown(reloaded.dispose);

      expect(reloaded.customKeyCommands.single.command, 'echo hello');
      expect(reloaded.customKeyCommands.single.modifiers, <Modifier>{
        Modifier.meta,
      });
      expect(
        reloaded.builtInKeyCommandOverrides.single.command,
        BuiltInKeyCommand.fullscreen,
      );
      expect(reloaded.builtInKeyCommandOverrides.single.modifiers, <Modifier>{
        Modifier.meta,
        Modifier.shift,
      });
    });

    test('plugins round-trip', () {
      config.plugins.add(const Plugin(path: '/usr/lib/plugin.so'));
      expect(config.plugins.single.path, '/usr/lib/plugin.so');
      config.plugins.removeAt(0);
      expect(config.plugins, isEmpty);
    });

    test('insert shifts the tail along', () {
      config.startupApps
        ..clear()
        ..add(const StartupApp(command: 'a'))
        ..add(const StartupApp(command: 'c'));
      config.startupApps.insert(1, const StartupApp(command: 'b'));
      expect(config.startupApps.map((app) => app.command), <String>[
        'a',
        'b',
        'c',
      ]);
    });

    test('out-of-range access throws', () {
      config.includes.clear();
      expect(() => config.includes[0], throwsRangeError);
      expect(() => config.includes[-1], throwsRangeError);
      expect(() => config.includes.insert(2, '/a'), throwsRangeError);
    });

    test('growing by setting length is refused', () {
      expect(() => config.includes.length = 5, throwsUnsupportedError);
    });
  }, skip: skip);

  group('animations', () {
    test('miracle defines a fixed set of events', () {
      expect(config.animateableEvents.map((event) => event.name), <String>[
        'window_open',
        'window_move',
        'window_close',
        'workspace_switch',
      ]);
      expect(() => config.animateableEvents.length = 0, throwsUnsupportedError);
      expect(
        () => config.animateableEvents.add(config.animateableEvents.first),
        throwsUnsupportedError,
      );
    });

    test('parts can be added, replaced and removed', () {
      final event = config.animateableEvents.first;
      final originalLength = event.parts.length;
      expect(event.isDefault, isTrue);

      event.parts.add(
        const BuiltInAnimation(
          type: AnimationType.slide,
          function: EaseFunction.easeInOutQuad,
        ),
      );
      expect(event.parts, hasLength(originalLength + 1));
      expect(event.isDefault, isFalse);
      expect(event.parts.last.type, AnimationType.slide);
      expect(event.parts.last.function, EaseFunction.easeInOutQuad);

      event.parts[0] = const BuiltInAnimation(
        type: AnimationType.grow,
        function: EaseFunction.easeOutBounce,
      );
      expect(event.parts.first.type, AnimationType.grow);

      event.parts.removeAt(event.parts.length - 1);
      expect(event.parts, hasLength(originalLength));
    });

    test('reset restores the default', () {
      final event = config.animateableEvents.first;
      final original = event.parts.toList();
      final duration = event.durationSeconds;

      event.durationSeconds = 0.75;
      event.parts.add(
        const BuiltInAnimation(
          type: AnimationType.fade,
          function: EaseFunction.linear,
        ),
      );
      expect(event.durationSeconds, closeTo(0.75, 0.001));
      expect(event.isDefault, isFalse);

      event.reset();
      expect(event.isDefault, isTrue);
      expect(event.parts, original);
      expect(event.durationSeconds, closeTo(duration, 0.001));
    });
  }, skip: skip);

  group('lifecycle', () {
    test('dispose is idempotent and guards every accessor', () {
      final other = MiracleConfig.load('${directory.path}/config.yaml');
      expect(other.isDisposed, isFalse);

      other.dispose();
      expect(other.isDisposed, isTrue);
      other.dispose();

      expect(() => other.innerGapsX, throwsStateError);
      expect(() => other.terminal, throwsStateError);
      expect(() => other.border.size, throwsStateError);
      expect(() => other.startupApps.length, throwsStateError);
      expect(() => other.animateableEvents.length, throwsStateError);
      expect(() => other.save(), throwsStateError);
    });

    test('errors and path survive disposal', () {
      final other = MiracleConfig.load('${directory.path}/config.yaml');
      final path = other.path;
      other.dispose();
      expect(other.path, path);
      expect(other.errors, isEmpty);
    });

    test('save reports where it wrote', () {
      final target = '${directory.path}/saved.yaml';
      final result = config.save(target);
      expect(result.success, isTrue);
      expect(result.errors, isEmpty);
      expect(File(target).existsSync(), isTrue);
    });
  }, skip: skip);

  group('enum parity with the C library', () {
    late MiracleConfigBindings bindings;

    setUp(() {
      if (!MiracleConfig.isAvailable) return;
      bindings = _openBindings();
    });

    /// Asserts that every Dart enum member appears in the C option table with
    /// the same name, so an upstream renumbering cannot pass unnoticed.
    void expectParity(
      String label,
      List<(String, int)> table,
      Map<int, String> dart,
    ) {
      final byValue = <int, String>{
        for (final (name, value) in table) value: name,
      };
      for (final entry in dart.entries) {
        expect(byValue, containsPair(entry.key, entry.value), reason: label);
      }
    }

    test('modifiers', () {
      expectParity(
        'Modifier',
        _options(
          bindings.miracle_config_get_modifier_options_count,
          bindings.miracle_config_get_modifier_option,
        ),
        <int, String>{for (final v in Modifier.values) v.value: v.wireName},
      );
    });

    test('mouse buttons and actions', () {
      expectParity(
        'MouseButton',
        _options(
          bindings.miracle_config_get_mouse_button_options_count,
          bindings.miracle_config_get_mouse_button_option,
        ),
        <int, String>{for (final v in MouseButton.values) v.value: v.wireName},
      );
      expectParity(
        'PointerAction',
        _options(
          bindings.miracle_config_get_mouse_actions_options_count,
          bindings.miracle_config_get_mouse_actions_option,
        ),
        <int, String>{
          for (final v in PointerAction.values) v.value: v.wireName,
        },
      );
    });

    test('keyboard actions', () {
      expectParity(
        'KeyboardAction',
        _options(
          bindings.miracle_config_get_keyboard_actions_options_count,
          bindings.miracle_config_get_keyboard_actions_option,
        ),
        <int, String>{
          for (final v in KeyboardAction.values) v.value: v.wireName,
        },
      );
    });

    test('built-in key commands', () {
      final table = _options(
        bindings.miracle_config_get_built_in_key_command_options_count,
        bindings.miracle_config_get_built_in_key_command_option,
      );
      expect(table, hasLength(BuiltInKeyCommand.values.length));
      expectParity('BuiltInKeyCommand', table, <int, String>{
        for (final v in BuiltInKeyCommand.values) v.value: v.wireName,
      });
    });

    test('animation types and ease functions', () {
      final types = _options(
        bindings.miracle_config_get_built_in_animation_type_options_count,
        bindings.miracle_config_get_built_in_animation_type_option,
      );
      expect(types, hasLength(AnimationType.values.length));
      expectParity('AnimationType', types, <int, String>{
        for (final v in AnimationType.values) v.value: v.wireName,
      });

      final functions = _options(
        bindings.miracle_config_get_ease_function_options_count,
        bindings.miracle_config_get_ease_function_option,
      );
      expect(functions, hasLength(EaseFunction.values.length));
      expectParity('EaseFunction', functions, <int, String>{
        for (final v in EaseFunction.values) v.value: v.wireName,
      });
    });

    test('handedness and acceleration', () {
      expectParity(
        'Handedness',
        _options(
          bindings.miracle_config_get_handedness_options_count,
          bindings.miracle_config_get_handedness_option,
        ),
        <int, String>{for (final v in Handedness.values) v.value: v.wireName},
      );

      final acceleration = _options(
        bindings.miracle_config_get_acceleration_options_count,
        bindings.miracle_config_get_acceleration_option,
      );
      expectParity('Acceleration', acceleration, <int, String>{
        for (final v in Acceleration.values) v.value: v.wireName,
      });
      // Index 0 is the C library's `default:` branch rather than a profile,
      // and duplicates `none`. Acceleration deliberately has no member for it.
      expect(acceleration[0], ('none', 0));
    });

    test('touchpad modes', () {
      expectParity(
        'TouchpadClickMode',
        _options(
          bindings.miracle_config_get_touchpad_click_mode_options_count,
          bindings.miracle_config_get_touchpad_click_mode_option,
        ),
        <int, String>{
          for (final v in TouchpadClickMode.values) v.value: v.wireName,
        },
      );
      expectParity(
        'TouchpadScrollMode',
        _options(
          bindings.miracle_config_get_touchpad_scroll_mode_options_count,
          bindings.miracle_config_get_touchpad_scroll_mode_option,
        ),
        <int, String>{
          for (final v in TouchpadScrollMode.values) v.value: v.wireName,
        },
      );
    });

    test('animateable event count', () {
      expect(
        bindings.miracle_config_get_animateable_event_count(),
        config.animateableEvents.length,
      );
    });
  }, skip: skip);
}

/// Saves [config] to a fresh file in [directory] and loads it back.
MiracleConfig _saveAndReload(MiracleConfig config, Directory directory) {
  final target = '${directory.path}/roundtrip.yaml';
  final result = config.save(target);
  expect(result.success, isTrue, reason: '${result.errors}');
  return MiracleConfig.load(target);
}

// Tests for the parts of the configuration API that do not need
// `libmiracle-wm-c`, so they run everywhere including CI.
import 'package:miracle/miracle.dart';
import 'package:test/test.dart';

void main() {
  group('enums', () {
    test('wire names are unique within each enum', () {
      void expectUniqueNames(String label, Iterable<String> names) {
        expect(names.toSet(), hasLength(names.length), reason: label);
      }

      expectUniqueNames('Modifier', Modifier.values.map((v) => v.wireName));
      expectUniqueNames(
        'MouseButton',
        MouseButton.values.map((v) => v.wireName),
      );
      expectUniqueNames(
        'PointerAction',
        PointerAction.values.map((v) => v.wireName),
      );
      expectUniqueNames(
        'KeyboardAction',
        KeyboardAction.values.map((v) => v.wireName),
      );
      expectUniqueNames(
        'BuiltInKeyCommand',
        BuiltInKeyCommand.values.map((v) => v.wireName),
      );
      expectUniqueNames(
        'AnimationType',
        AnimationType.values.map((v) => v.wireName),
      );
      expectUniqueNames(
        'EaseFunction',
        EaseFunction.values.map((v) => v.wireName),
      );
      expectUniqueNames(
        'CursorFocusMode',
        CursorFocusMode.values.map((v) => v.wireName),
      );
      expectUniqueNames('Handedness', Handedness.values.map((v) => v.wireName));
      expectUniqueNames(
        'Acceleration',
        Acceleration.values.map((v) => v.wireName),
      );
      expectUniqueNames(
        'TouchpadClickMode',
        TouchpadClickMode.values.map((v) => v.wireName),
      );
      expectUniqueNames(
        'TouchpadScrollMode',
        TouchpadScrollMode.values.map((v) => v.wireName),
      );
    });

    test('values are unique within each enum', () {
      void expectUniqueValues(String label, Iterable<int> values) {
        expect(values.toSet(), hasLength(values.length), reason: label);
      }

      expectUniqueValues('Modifier', Modifier.values.map((v) => v.value));
      expectUniqueValues('MouseButton', MouseButton.values.map((v) => v.value));
      expectUniqueValues(
        'BuiltInKeyCommand',
        BuiltInKeyCommand.values.map((v) => v.value),
      );
      expectUniqueValues(
        'EaseFunction',
        EaseFunction.values.map((v) => v.value),
      );
      expectUniqueValues(
        'TouchpadScrollMode',
        TouchpadScrollMode.values.map((v) => v.value),
      );
    });

    test('fromString round-trips', () {
      for (final modifier in Modifier.values) {
        expect(Modifier.fromString(modifier.wireName), modifier);
      }
      for (final command in BuiltInKeyCommand.values) {
        expect(BuiltInKeyCommand.fromString(command.wireName), command);
      }
      for (final function in EaseFunction.values) {
        expect(EaseFunction.fromString(function.wireName), function);
      }
    });

    test('fromValue round-trips', () {
      for (final modifier in Modifier.values) {
        expect(Modifier.fromValue(modifier.value), modifier);
      }
      for (final mode in TouchpadScrollMode.values) {
        expect(TouchpadScrollMode.fromValue(mode.value), mode);
      }
      for (final acceleration in Acceleration.values) {
        expect(Acceleration.fromValue(acceleration.value), acceleration);
      }
    });

    test('unknown names and values give null', () {
      expect(Modifier.fromString('hyper'), isNull);
      expect(Modifier.fromValue(1 << 30), isNull);
      expect(BuiltInKeyCommand.fromString('explode'), isNull);
      expect(EaseFunction.fromValue(999), isNull);
    });

    test('modifiers are distinct bits', () {
      for (final modifier in Modifier.values) {
        expect(
          modifier.value & (modifier.value - 1),
          0,
          reason: '${modifier.wireName} is not a single bit',
        );
      }
    });

    // Mir numbers acceleration from 1, and the C library's option table
    // reports a spurious entry at index 0. Neither should leak into the enum.
    test('Acceleration skips the C library\'s phantom index 0', () {
      expect(Acceleration.fromValue(0), isNull);
      expect(Acceleration.none.value, 1);
      expect(Acceleration.adaptive.value, 2);
      expect(Acceleration.adaptive.wireName, 'adapative');
    });

    test('TouchpadScrollMode uses Mir\'s bit flags', () {
      expect(TouchpadScrollMode.buttonDownScroll.value, 4);
    });
  });

  group('value types', () {
    test('RgbaColor equality and copyWith', () {
      const color = RgbaColor(red: 0.1, green: 0.2, blue: 0.3);
      expect(color, const RgbaColor(red: 0.1, green: 0.2, blue: 0.3));
      expect(color.alpha, 1.0);
      expect(
        color.copyWith(red: 0.9),
        const RgbaColor(red: 0.9, green: 0.2, blue: 0.3),
      );
      expect(
        color.hashCode,
        const RgbaColor(red: 0.1, green: 0.2, blue: 0.3).hashCode,
      );
    });

    test('RgbaColor.fromBytes scales to unit range', () {
      const white = RgbaColor(red: 1, green: 1, blue: 1);
      expect(RgbaColor.fromBytes(255, 255, 255), white);
      expect(
        RgbaColor.fromBytes(0, 0, 0, 0),
        const RgbaColor(red: 0, green: 0, blue: 0, alpha: 0),
      );
    });

    test('CustomKeyCommand compares modifiers by content', () {
      const a = CustomKeyCommand(
        key: 33,
        command: 'echo',
        modifiers: <Modifier>{Modifier.meta, Modifier.shift},
      );
      const b = CustomKeyCommand(
        key: 33,
        command: 'echo',
        modifiers: <Modifier>{Modifier.shift, Modifier.meta},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(key: 34), isNot(a));
    });

    test('KeyCommandOverride compares modifiers by content', () {
      const a = KeyCommandOverride(
        key: 33,
        command: BuiltInKeyCommand.fullscreen,
        modifiers: <Modifier>{Modifier.meta, Modifier.shift},
      );
      const b = KeyCommandOverride(
        key: 33,
        command: BuiltInKeyCommand.fullscreen,
        modifiers: <Modifier>{Modifier.shift, Modifier.meta},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('WorkspaceConfig.copyWith can unset fields', () {
      const workspace = WorkspaceConfig(number: 3, name: 'code');
      expect(
        workspace.copyWith(clearName: true),
        const WorkspaceConfig(number: 3),
      );
      expect(
        workspace.copyWith(clearNumber: true),
        const WorkspaceConfig(name: 'code'),
      );
      expect(workspace.copyWith(name: 'web').name, 'web');
    });

    test('StartupApp equality and copyWith', () {
      const app = StartupApp(command: 'nm-applet', restartOnDeath: true);
      expect(app, const StartupApp(command: 'nm-applet', restartOnDeath: true));
      expect(app.copyWith(noStartupId: true).noStartupId, isTrue);
      expect(app.copyWith(noStartupId: true), isNot(app));
    });

    test('MiracleConfigError describes itself', () {
      const error = MiracleConfigError(
        line: 4,
        column: 2,
        level: MiracleConfigErrorLevel.warning,
        filename: '/tmp/config.yaml',
        message: 'unknown key',
      );
      expect(
        error.toString(),
        'MiracleConfigError(warning, /tmp/config.yaml:4:2: unknown key)',
      );
    });

    test('BuiltInAnimation equality and copyWith', () {
      const animation = BuiltInAnimation(
        type: AnimationType.slide,
        function: EaseFunction.linear,
      );
      expect(animation, animation.copyWith());
      expect(animation.copyWith(c1: 1.5).c1, 1.5);
      expect(animation.copyWith(c1: 1.5), isNot(animation));
    });
  });

  group('MiracleConfigException', () {
    test('describes itself', () {
      expect(
        MiracleConfigException('nope').toString(),
        'MiracleConfigException: nope',
      );
    });
  });

  group('availability', () {
    test('isAvailable does not throw', () {
      expect(MiracleConfig.isAvailable, isA<bool>());
    });

    test('everything else throws when the library is missing', () {
      // On a machine with miracle-wm installed this is not exercised, which is
      // the point: the check has to be cheap enough to always run.
      if (MiracleConfig.isAvailable) return;
      expect(
        () => MiracleConfig.defaultConfigPath,
        throwsA(isA<MiracleConfigException>()),
      );
      expect(
        () => MiracleConfig.load('/tmp/nope.yaml'),
        throwsA(isA<MiracleConfigException>()),
      );
    });
  });
}

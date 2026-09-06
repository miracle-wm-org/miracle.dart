// Reads miracle-wm's configuration, changes a few settings and writes it back.
//
// Run with: dart run example/miracle_config_example.dart
//
// This needs `libmiracle-wm-c` on the system, which miracle-wm 0.10 and newer
// install alongside the compositor.
import 'package:miracle/miracle.dart';

void main() {
  if (!MiracleConfig.isAvailable) {
    print('libmiracle-wm-c is not installed; nothing to do.');
    return;
  }

  print('Reading ${MiracleConfig.defaultConfigPath}');

  final config = MiracleConfig.loadDefault();
  try {
    for (final error in config.errors) {
      print('  ${error.level.wireName}: $error');
    }

    print(
      'Gaps        ${config.innerGapsX}x${config.innerGapsY} inner, '
      '${config.outerGapsX}x${config.outerGapsY} outer',
    );
    print('Terminal    ${config.terminal ?? '(default)'}');
    print('Action key  ${config.primaryModifier.wireName}');
    print(
      'Border      ${config.border.size}px, '
      'radius ${config.border.radius}',
    );
    print('Background  ${config.backgroundColor}');

    print('Startup apps:');
    for (final app in config.startupApps) {
      print(
        '  ${app.command}'
        '${app.restartOnDeath ? ' (restarts on death)' : ''}',
      );
    }

    print('Animations ${config.animationsEnabled ? 'on' : 'off'}:');
    for (final event in config.animateableEvents) {
      final parts = event.parts.map((part) => part.type.wireName).join(', ');
      print('  ${event.name}: ${event.durationSeconds}s [$parts]');
    }

    // Everything is a plain setter, and nothing touches the disk until save().
    config
      ..innerGapsX = 10
      ..innerGapsY = 10
      ..animationsEnabled = true;
    config.border.radius = 8;
    config.startupApps.add(
      const StartupApp(command: 'nm-applet', restartOnDeath: true),
    );

    // Written to a copy so that running the example does not clobber a real
    // configuration; pass no argument to write back where it was loaded from.
    final result = config.save('${MiracleConfig.defaultConfigPath}.example');
    print(
      result.success
          ? 'Saved to ${MiracleConfig.defaultConfigPath}.example'
          : 'Save failed: ${result.errors}',
    );
  } finally {
    // The configuration is native memory; a finalizer would eventually free it,
    // but disposing explicitly is better.
    config.dispose();
  }
}

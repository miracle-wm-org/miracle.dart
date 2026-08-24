import 'package:miracle/miracle.dart';
import 'package:test/test.dart';

void main() {
  group('exec', () {
    test('builds an exec command', () {
      expect(MiracleCommand.exec('gedit').toCommandString(), 'exec gedit');
    });

    test('supports --no-startup-id', () {
      expect(MiracleCommand.exec('urxvt', noStartupId: true).toCommandString(),
          'exec --no-startup-id urxvt');
    });
  });

  group('split and layout', () {
    test('builds split commands', () {
      expect(MiracleCommand.split(SplitDirection.vertical).toCommandString(),
          'split vertical');
      expect(MiracleCommand.split(SplitDirection.toggle).toCommandString(),
          'split toggle');
    });

    test('builds layout commands', () {
      expect(MiracleCommand.layout(LayoutMode.splitv).toCommandString(),
          'layout splitv');
      expect(MiracleCommand.layout(LayoutMode.defaultLayout).toCommandString(),
          'layout default');
      expect(MiracleCommand.layoutToggleSplit().toCommandString(),
          'layout toggle split');
      expect(MiracleCommand.layoutToggleAll().toCommandString(),
          'layout toggle all');
      expect(
        MiracleCommand.layoutToggleAmong(
                [LayoutMode.tabbed, LayoutMode.splith, LayoutMode.splitv])
            .toCommandString(),
        'layout toggle tabbed splith splitv',
      );
    });

    test('rejects an empty layout cycle', () {
      expect(() => MiracleCommand.layoutToggleAmong([]),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('focus', () {
    test('builds directional and relative focus commands', () {
      expect(MiracleCommand.focusDirection(Direction.right).toCommandString(),
          'focus right');
      expect(MiracleCommand.focusTarget(FocusTarget.modeToggle).toCommandString(),
          'focus mode_toggle');
      expect(MiracleCommand.focusSibling(FocusSibling.next).toCommandString(),
          'focus next');
      expect(
        MiracleCommand.focusSibling(FocusSibling.prev, includeNonLeaf: true)
            .toCommandString(),
        'focus prev sibling',
      );
    });

    test('prefixes criteria', () {
      expect(
        MiracleCommand.focusMatching(const Criteria(pid: 1234))
            .toCommandString(),
        '[pid=1234] focus',
      );
      expect(
        MiracleCommand.focusWorkspaceOf(const Criteria(appId: 'firefox'))
            .toCommandString(),
        '[app_id="firefox"] focus workspace',
      );
    });

    test('builds output focus commands', () {
      expect(
        MiracleCommand.focusOutput(OutputSelector.direction(Direction.left))
            .toCommandString(),
        'focus output left',
      );
      expect(
        MiracleCommand.focusOutput(OutputSelector.named(['VGA-1', 'VGA-2']))
            .toCommandString(),
        'focus output VGA-1 VGA-2',
      );
      expect(MiracleCommand.focusOutput(OutputSelector.nonPrimary())
          .toCommandString(), 'focus output nonprimary');
    });

    test('rejects an empty output list', () {
      expect(() => OutputSelector.named([]), throwsA(isA<ArgumentError>()));
    });
  });

  group('move', () {
    test('builds directional moves', () {
      expect(MiracleCommand.move(Direction.left).toCommandString(),
          'move left');
      expect(MiracleCommand.move(Direction.left, amount: 20).toCommandString(),
          'move left 20 px');
      expect(
        MiracleCommand.move(Direction.up, amount: 10, unit: SizeUnit.ppt)
            .toCommandString(),
        'move up 10 ppt',
      );
    });

    test('builds positional moves', () {
      expect(
        MiracleCommand.moveToPosition(10, 10,
                xUnit: SizeUnit.ppt, yUnit: SizeUnit.ppt)
            .toCommandString(),
        'move position 10 ppt 10 ppt',
      );
      expect(MiracleCommand.moveToCenter().toCommandString(),
          'move position center');
      expect(MiracleCommand.moveToCenter(absolute: true).toCommandString(),
          'move absolute position center');
      expect(MiracleCommand.moveToMouse().toCommandString(),
          'move position mouse');
    });

    test('builds mark, workspace and output moves', () {
      expect(MiracleCommand.moveToMark('meow').toCommandString(),
          'move container to mark meow');
      expect(MiracleCommand.moveToWorkspace('1').toCommandString(),
          'move container to workspace 1');
      expect(
        MiracleCommand.moveToWorkspace('2: hi').toCommandString(),
        'move container to workspace "2: hi"',
      );
      expect(
        MiracleCommand.moveToWorkspace('1', noAutoBackAndForth: true)
            .toCommandString(),
        'move --no-auto-back-and-forth container to workspace 1',
      );
      expect(MiracleCommand.moveToWorkspaceNumber('3').toCommandString(),
          'move container to workspace number 3');
      expect(
        MiracleCommand.moveToRelativeWorkspace(RelativeWorkspace.next)
            .toCommandString(),
        'move container to workspace next',
      );
      expect(
        MiracleCommand.moveToOutput(OutputSelector.direction(Direction.right))
            .toCommandString(),
        'move container to output right',
      );
      expect(
        MiracleCommand.moveWorkspaceToOutput(
                OutputSelector.direction(Direction.right))
            .toCommandString(),
        'move workspace to output right',
      );
    });
  });

  group('marks', () {
    test('builds mark commands', () {
      expect(MiracleCommand.mark('hi').toCommandString(), 'mark hi');
      expect(
        MiracleCommand.mark('hi', mode: MarkMode.add, toggle: true)
            .toCommandString(),
        'mark --add --toggle hi',
      );
      expect(
        MiracleCommand.mark('hi', mode: MarkMode.replace).toCommandString(),
        'mark --replace hi',
      );
    });

    test('builds unmark commands', () {
      expect(MiracleCommand.unmark().toCommandString(), 'unmark');
      expect(MiracleCommand.unmark('hi').toCommandString(), 'unmark hi');
    });
  });

  group('resize, swap and sticky', () {
    test('builds resize commands', () {
      expect(
        MiracleCommand.resize(ResizeMode.grow, ResizeAxis.width, 10)
            .toCommandString(),
        'resize grow width 10 px',
      );
      expect(
        MiracleCommand.resize(ResizeMode.shrink, ResizeAxis.height, 10,
                unit: SizeUnit.ppt)
            .toCommandString(),
        'resize shrink height 10 ppt',
      );
      expect(
        MiracleCommand.resizeSet(
                width: 100, height: 50, heightUnit: SizeUnit.ppt)
            .toCommandString(),
        'resize set 100 px 50 ppt',
      );
    });

    test('builds swap commands', () {
      expect(MiracleCommand.swapWithMark('swapee').toCommandString(),
          'swap container with mark swapee');
      expect(MiracleCommand.swapWithId('firefox').toCommandString(),
          'swap container with id firefox');
    });

    test('builds sticky commands', () {
      expect(MiracleCommand.sticky(Toggle.enable).toCommandString(),
          'sticky enable');
      expect(MiracleCommand.sticky(Toggle.toggle).toCommandString(),
          'sticky toggle');
    });
  });

  group('workspace and rename', () {
    test('builds workspace commands', () {
      expect(MiracleCommand.workspace('hello').toCommandString(),
          'workspace hello');
      expect(
        MiracleCommand.workspace('hi', noAutoBackAndForth: true)
            .toCommandString(),
        'workspace --no-auto-back-and-forth hi',
      );
      expect(MiracleCommand.workspaceNumber('2').toCommandString(),
          'workspace number 2');
      expect(
        MiracleCommand.workspaceDirection(WorkspaceDirection.nextOnOutput)
            .toCommandString(),
        'workspace next_on_output',
      );
      expect(MiracleCommand.workspaceBackAndForth().toCommandString(),
          'workspace back_and_forth');
    });

    test('builds rename commands', () {
      expect(MiracleCommand.renameWorkspace(to: '3').toCommandString(),
          'rename workspace to 3');
      expect(
        MiracleCommand.renameWorkspace(from: '1', to: '2: hi')
            .toCommandString(),
        'rename workspace 1 to "2: hi"',
      );
    });
  });

  group('gaps, scratchpad, nop and debug', () {
    test('builds gaps commands', () {
      expect(
        MiracleCommand.gaps(
          kind: GapKind.outer,
          scope: GapScope.all,
          operation: GapOperation.set,
          pixels: 100,
        ).toCommandString(),
        'gaps outer all set 100',
      );
      expect(
        MiracleCommand.gaps(
          kind: GapKind.inner,
          scope: GapScope.current,
          operation: GapOperation.plus,
          pixels: 10,
        ).toCommandString(),
        'gaps inner current plus 10',
      );
    });

    test('builds scratchpad commands', () {
      expect(MiracleCommand.moveToScratchpad().toCommandString(),
          'move scratchpad');
      expect(MiracleCommand.scratchpadShow().toCommandString(),
          'scratchpad show');
      expect(
        MiracleCommand.scratchpadShow(criteria: const Criteria(pid: 1234))
            .toCommandString(),
        '[pid=1234] scratchpad show',
      );
    });

    test('builds nop and debug commands', () {
      expect(MiracleCommand.nop().toCommandString(), 'nop');
      expect(MiracleCommand.debugOverlay().toCommandString(),
          'debug overlay toggle');
      expect(MiracleCommand.debugOverlay(Toggle.enable).toCommandString(),
          'debug overlay on');
      expect(MiracleCommand.debugOverlay(Toggle.disable).toCommandString(),
          'debug overlay off');
    });

    test('passes a raw command through untouched', () {
      expect(
        const MiracleCommand.raw('fullscreen toggle').toCommandString(),
        'fullscreen toggle',
      );
    });
  });

  group('criteria', () {
    test('quotes every string value', () {
      const criteria = Criteria(
        appId: 'firefox',
        className: 'URxvt',
        instance: 'urxvt',
        title: 'a window',
        mark: 'editor',
        workspace: '1',
        urgent: 'latest',
      );

      expect(
        criteria.toString(),
        '[app_id="firefox" class="URxvt" instance="urxvt" title="a window" '
        'con_mark="editor" workspace="1" urgent="latest"]',
      );
    });

    test('emits numeric and bare criteria unquoted', () {
      expect(const Criteria(pid: 12, containerId: 7, floating: true).toString(),
          '[pid=12 con_id=7 floating]');
      expect(const Criteria(tiling: true, all: true).toString(),
          '[tiling all]');
    });

    test('is dropped when empty', () {
      expect(const Criteria().isEmpty, isTrue);
      expect(
        const MiracleCommand.raw('nop', criteria: Criteria()).toCommandString(),
        'nop',
      );
    });

    test('escapes quotes in values', () {
      expect(const Criteria(title: 'say "hi"').toString(),
          r'[title="say \"hi\""]');
    });
  });

  test('joinCommands separates commands with a semicolon', () {
    expect(
      joinCommands([
        MiracleCommand.nop(),
        MiracleCommand.workspace('2'),
      ]),
      'nop; workspace 2',
    );
  });
}

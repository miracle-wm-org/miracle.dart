import 'dart:convert';

import 'package:miracle/miracle.dart';
import 'package:test/test.dart';

import 'fake_miracle.dart';

void main() {
  late FakeMiracle miracle;
  late MiracleConnection connection;

  setUp(() async {
    miracle = await FakeMiracle.start();
    connection = MiracleConnection();
    await connection.connect(socketPath: miracle.socketPath);
  });

  tearDown(() async {
    await connection.disconnect();
    await miracle.stop();
  });

  /// Replies to every request with [payload].
  void replyWith(Object? payload) {
    miracle.onRequest = (type, request) => jsonEncode(payload);
  }

  group('requests', () {
    test('RUN_COMMAND reports parse errors as booleans', () async {
      replyWith([
        {'success': true},
        {
          'success': false,
          'parse_error': true,
          'error': 'Unsupported command type: meow',
        },
      ]);

      final results = await connection.command('resize grow width 10; meow 5');

      expect(results, hasLength(2));
      expect(results.first.success, isTrue);
      expect(results.first.parseError, isFalse);
      expect(results.last.success, isFalse);
      expect(results.last.parseError, isTrue);
      expect(results.last.error, 'Unsupported command type: meow');
      expect(miracle.requests.single.$1, IpcType.ipcCommand.value);
      expect(miracle.requests.single.$2, 'resize grow width 10; meow 5');
    });

    test('run sends a typed command', () async {
      replyWith([
        {'success': true}
      ]);

      await connection.run(MiracleCommand.workspace('2'));

      expect(miracle.requests.single.$2, 'workspace 2');
    });

    test('runAll joins commands', () async {
      replyWith([
        {'success': true},
        {'success': true},
      ]);

      await connection.runAll([
        MiracleCommand.mark('swapee'),
        MiracleCommand.swapWithMark('swapee'),
      ]);

      expect(miracle.requests.single.$2,
          'mark swapee; swap container with mark swapee');
    });

    test('runOrThrow throws when miracle reports a failure', () async {
      replyWith([
        {'success': false, 'parse_error': true, 'error': 'nope'},
      ]);

      expect(
        () => connection.runOrThrow(MiracleCommand.nop()),
        throwsA(isA<MiracleCommandException>()),
      );
    });

    test('GET_WORKSPACES tolerates the fields miracle omits', () async {
      replyWith([
        {
          'num': 1,
          'name': '1',
          'visible': true,
          'focused': true,
          'output': 'eDP-1',
          'rect': {'x': 0, 'y': 23, 'width': 1920, 'height': 1057},
        }
      ]);

      final workspaces = await connection.getWorkspaces();

      expect(workspaces.single.num, 1);
      expect(workspaces.single.output, 'eDP-1');
      // `urgent` is absent from the documented payload.
      expect(workspaces.single.urgent, isFalse);
      expect(workspaces.single.rect,
          const Rect(x: 0, y: 23, width: 1920, height: 1057));
    });

    test('GET_WORKSPACES reports an urgent workspace', () async {
      replyWith([
        {
          'num': 2,
          'name': '2',
          'visible': false,
          'focused': false,
          'urgent': true,
          'output': 'eDP-1',
          'rect': {'x': 0, 'y': 23, 'width': 1920, 'height': 1057},
        }
      ]);

      final workspaces = await connection.getWorkspaces();

      expect(workspaces.single.urgent, isTrue);
    });

    test('GET_OUTPUTS returns typed outputs', () async {
      replyWith([
        {
          'name': 'HDMI-A-2',
          'make': 'Unknown',
          'model': 'NS-19E310A13',
          'serial': '0x00000001',
          'active': true,
          'dpms': true,
          'primary': false,
          'scale': 1.0,
          'subpixel_hinting': 'rgb',
          'transform': 'normal',
          'current_workspace': '1',
          'modes': [
            {'width': 640, 'height': 480, 'refresh': 59940},
            {'width': 1920, 'height': 1080, 'refresh': 60000},
          ],
          'current_mode': {'width': 1920, 'height': 1080, 'refresh': 60000},
        }
      ]);

      final outputs = await connection.getOutputs();
      final output = outputs.single;

      expect(output.name, 'HDMI-A-2');
      expect(output.primary, isFalse);
      expect(output.subpixelHinting, SubpixelHinting.rgb);
      expect(output.transform, OutputTransform.normal);
      expect(output.currentWorkspace, '1');
      expect(output.modes, hasLength(2));
      // `power` is absent here, and mirrors the deprecated `dpms`.
      expect(output.power, isTrue);
      expect(output.currentMode?.refreshHz, 60);
      expect(miracle.requests.single.$1, IpcType.ipcGetOutputs.value);
    });

    test('GET_OUTPUTS survives an inactive output reporting scale -1',
        () async {
      replyWith([
        {'name': 'HDMI-A-1', 'active': false, 'scale': -1},
      ]);

      expect((await connection.getOutputs()).single.scale, -1);
    });

    test('GET_MARKS returns the unique marks', () async {
      replyWith(['editor', 'browser']);
      expect((await connection.getMarks()).marks, ['editor', 'browser']);
    });

    test('GET_VERSION knows how it compares to other versions', () async {
      replyWith({
        'major': 0,
        'minor': 10,
        'patch': 2,
        'human_readable': '0.10.2',
        'loaded_config_file_name': '/home/user/.config/miracle-wm/config.yaml',
      });

      final version = await connection.getVersion();

      expect(version.humanReadable, '0.10.2');
      expect(version.isAtLeast(0, 10), isTrue);
      expect(version.isAtLeast(0, 11), isFalse);
    });

    test('GET_BINDING_MODES and GET_BINDING_STATE', () async {
      miracle.onRequest = (type, payload) =>
          type == IpcType.ipcGetBindingModes.value
              ? jsonEncode(['default', 'resize'])
              : jsonEncode({'name': 'resize'});

      expect((await connection.getBindingModes()).modes, ['default', 'resize']);
      expect((await connection.getBindingState()).name, 'resize');
    });

    test('SEND_TICK forwards a string payload verbatim', () async {
      replyWith({'success': true});

      expect((await connection.sendTick('hello')).success, isTrue);
      expect(miracle.requests.single.$2, 'hello');
    });

    test('SEND_TICK encodes a non-string payload as JSON', () async {
      replyWith({'success': true});

      await connection.sendTick({'id': 7});

      expect(miracle.requests.single.$2, '{"id":7}');
    });

    test('SEND_TICK sends nothing when there is no payload', () async {
      replyWith({'success': true});

      await connection.sendTick();

      expect(miracle.requests.single.$2, isEmpty);
    });

    test('SYNC always answers "default"', () async {
      replyWith({'name': 'default'});
      expect((await connection.sync()).name, 'default');
    });

    test('GET_DEBUG_STATE returns a snapshot', () async {
      replyWith({
        'cursor': {'x': 100, 'y': 200},
        'window_under_cursor': 12,
        'windows': [
          {
            'debug_id': 12,
            'rect': {'x': 0, 'y': 0, 'width': 800, 'height': 600},
            'window_rect': {'x': 2, 'y': 2, 'width': 796, 'height': 596},
            'input_bounds': {'x': 0, 'y': 0, 'width': 800, 'height': 600},
            'input_region': [],
            'content_size': {'width': 796, 'height': 596},
            'focused': true,
            'visible': true,
            'app_id': 'kitty',
            'name': 'kitty',
            'output': 'eDP-1',
            'output_focused': true,
            'workspace_id': 3,
            'workspace_name': '1',
          }
        ],
      });

      final state = await connection.getDebugState();

      expect(state.cursor, const Position(x: 100, y: 200));
      expect(state.windowUnderCursor, 12);
      expect(state.windowUnderCursorInfo?.appId, 'kitty');
      expect(state.windows.single.acceptsInputEverywhere, isTrue);
      expect(state.windows.single.contentSize,
          const Size(width: 796, height: 596));
      expect(state.windowsOnOutput('eDP-1'), hasLength(1));
      expect(miracle.requests.single.$1, IpcType.ipcGetDebugState.value);
    });

    test('GET_DEBUG_STATE maps -1 to no window under the cursor', () async {
      replyWith({
        'cursor': {'x': 0, 'y': 0},
        'window_under_cursor': -1,
        'windows': [],
      });

      final state = await connection.getDebugState();

      expect(state.windowUnderCursor, isNull);
      expect(state.windowUnderCursorInfo, isNull);
    });

    test('PLUGIN_COMMAND routes a payload to a namespace', () async {
      replyWith({
        'success': true,
        'response': {'toggled': true},
      });

      final result = await connection.pluginCommand(
        'my-plugin',
        {'action': 'toggle', 'value': 42},
      );

      expect(result.success, isTrue);
      expect(result.responseObject, {'toggled': true});
      expect(miracle.requests.single.$1, IpcType.ipcPluginCommand.value);
      expect(jsonDecode(miracle.requests.single.$2), {
        'plugin': 'my-plugin',
        'payload': {'action': 'toggle', 'value': 42},
      });
    });

    test('PLUGIN_COMMAND surfaces an unowned namespace', () async {
      replyWith({
        'success': false,
        'error': 'No plugin is registered for namespace: nope',
      });

      final result = await connection.pluginCommand('nope');

      expect(result.success, isFalse);
      expect(result.error, contains('nope'));
    });

    test('concurrent requests of the same type resolve in order', () async {
      var replies = 0;
      miracle.onRequest = (type, payload) =>
          jsonEncode({'name': 'reply-${replies++}'});

      final results = await Future.wait([
        connection.sync(),
        connection.sync(),
        connection.sync(),
      ]);

      expect(results.map((result) => result.name),
          ['reply-0', 'reply-1', 'reply-2']);
    });

    test('in-flight requests fail when the connection is closed', () async {
      // No reply is configured, so the request stays in flight.
      miracle.onRequest = null;
      final expectation =
          expectLater(connection.sync(), throwsA(isA<Exception>()));
      await miracle.stop();

      await expectation;
    });
  });

  group('subscribe', () {
    test('sends the wire names of every event', () async {
      replyWith({'success': true});

      final result = await connection.subscribe([
        SubscriptionType.workspace,
        SubscriptionType.configErrors,
      ]);

      expect(result.success, isTrue);
      expect(jsonDecode(miracle.requests.single.$2),
          ['workspace', 'config_errors']);
    });

    test('mixes plugin namespaces in with event names', () async {
      replyWith({'success': true});

      await connection.subscribe(
        [SubscriptionType.workspace],
        pluginNamespaces: ['my-plugin', 'other-plugin'],
      );

      expect(jsonDecode(miracle.requests.single.$2),
          ['workspace', 'my-plugin', 'other-plugin']);
    });

    test('subscribeToPlugin sends only the namespace', () async {
      replyWith({'success': true});

      await connection.subscribeToPlugin('my-plugin');

      expect(jsonDecode(miracle.requests.single.$2), ['my-plugin']);
    });

    test('subscribeToAll covers every documented event', () async {
      replyWith({'success': true});

      await connection.subscribeToAll();

      expect(
        jsonDecode(miracle.requests.single.$2),
        containsAll([
          'workspace',
          'output',
          'mode',
          'window',
          'binding',
          'shutdown',
          'tick',
          'input',
          'config_errors',
        ]),
      );
    });

    test('rejects a plugin namespace that shadows an event name', () {
      expect(
        () => connection.subscribe(const [], pluginNamespaces: ['window']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('surfaces a rejected subscription', () async {
      replyWith({'success': false, 'error': 'Invalid IPC subscription event'});

      final result = await connection.subscribe([SubscriptionType.window]);

      expect(result.success, isFalse);
      expect(result.error, 'Invalid IPC subscription event');
    });
  });

  group('events', () {
    test('delivers a workspace focus event', () async {
      final event = connection.workspaceEvents.first;

      miracle.pushEvent(IpcType.ipcEventWorkspace.value, {
        'change': 'focus',
        'old': {'id': 1, 'name': '1', 'type': 'workspace', 'num': 1},
        'current': {'id': 2, 'name': '2', 'type': 'workspace', 'num': 2},
      });

      final workspace = await event;
      expect(workspace.change, WorkspaceChange.focus);
      expect(workspace.old?.name, '1');
      expect(workspace.current?.name, '2');
    });

    test('delivers a workspace reload event with no workspace', () async {
      final event = connection.workspaceEvents.first;

      miracle.pushEvent(IpcType.ipcEventWorkspace.value, {'change': 'reload'});

      final workspace = await event;
      expect(workspace.change, WorkspaceChange.reload);
      expect(workspace.current, isNull);
    });

    test('delivers a window event carrying a partial container', () async {
      final event = connection.windowEvents.first;

      // The container in the documented window event omits `sticky`,
      // `visible`, `shell` and friends.
      miracle.pushEvent(IpcType.ipcEventWindow.value, {
        'change': 'new',
        'container': {
          'id': 12,
          'name': null,
          'type': 'con',
          'rect': {'x': 0, 'y': 0, 'width': 0, 'height': 0},
          'focused': false,
          'focus': [],
          'border': 'none',
          'current_border_width': 0,
          'layout': 'none',
          'percent': 0.0,
          'window': 4194313,
          'urgent': false,
          'floating_nodes': [],
          'pid': 19787,
          'app_id': null,
          'window_properties': {
            'class': 'URxvt',
            'instance': 'urxvt',
            'transient_for': null,
          },
          'nodes': [],
        },
      });

      final window = await event;
      expect(window.change, WindowChange.created);
      expect(window.container.id, 12);
      expect(window.container.pid, 19787);
      expect(window.container.isWindow, isTrue);
      expect(window.container.windowProperties.className, 'URxvt');
    });

    test('delivers a window urgency event', () async {
      final event = connection.windowEvents.first;

      miracle.pushEvent(IpcType.ipcEventWindow.value, {
        'change': 'urgent',
        'container': {
          'id': 12,
          'name': 'kitty',
          'type': 'con',
          'rect': {'x': 0, 'y': 0, 'width': 0, 'height': 0},
          'window': 4194313,
          'urgent': true,
          'nodes': [],
        },
      });

      final window = await event;
      expect(window.change, WindowChange.urgent);
      expect(window.container.urgent, isTrue);
      expect(window.container.isUrgent, isTrue);
    });

    test('delivers the workspace urgency event sent alongside it', () async {
      final event = connection.workspaceEvents.first;

      // miracle sends this so that a bar watching workspaces rather than
      // windows sees the change too. It carries no `old` workspace.
      miracle.pushEvent(IpcType.ipcEventWorkspace.value, {
        'change': 'urgent',
        'old': null,
        'current': {
          'id': 2,
          'name': '2',
          'type': 'workspace',
          'num': 2,
          'urgent': true,
        },
      });

      final workspace = await event;
      expect(workspace.change, WorkspaceChange.urgent);
      expect(workspace.old, isNull);
      expect(workspace.current?.urgent, isTrue);
    });

    test('delivers output, mode, binding, shutdown and tick events', () async {
      final events = connection.take(5).toList();

      miracle
        ..pushEvent(IpcType.ipcEventOutput.value, {'change': 'unspecified'})
        ..pushEvent(IpcType.ipcEventMode.value,
            {'change': 'resize', 'pango_markup': true})
        ..pushEvent(IpcType.ipcEventBinding.value, {
          'change': 'run',
          'binding': {
            'command': 'workspace 2',
            'event_state_mask': ['meta'],
            'input_code': 0,
            'symbol': '2',
            'input_type': 'keyboard',
          },
        })
        ..pushEvent(IpcType.ipcEventTick.value, {'first': true, 'payload': ''})
        ..pushEvent(IpcType.ipcEventShutdown.value, {'change': 'exit'});

      final received = await events;

      expect((received[0] as OutputEvent).change, OutputChange.unspecified);
      expect((received[1] as ModeEvent).mode, 'resize');
      expect((received[1] as ModeEvent).isDefault, isFalse);

      final binding = received[2] as BindingEvent;
      expect(binding.binding.command, 'workspace 2');
      expect(binding.binding.hasModifier('meta'), isTrue);
      expect(binding.binding.inputType, BindingInputType.keyboard);

      expect((received[3] as TickEvent).first, isTrue);
      expect((received[4] as ShutdownEvent).change, ShutdownChange.exit);
    });

    test('reads the binding input type miracle actually emits', () async {
      final event = connection.bindingEvents.first;

      // miracle emits `type` where the wiki documents `input_type`.
      miracle.pushEvent(IpcType.ipcEventBinding.value, {
        'change': 'run',
        'binding': {
          'command': 'nop',
          'event_state_mask': [],
          'input_code': 0,
          'type': 'mouse',
        },
      });

      expect((await event).binding.inputType, BindingInputType.mouse);
    });

    test('delivers config errors, which arrive as a JSON array', () async {
      final event = connection.configErrorEvents.first;

      miracle.pushEvent(IpcType.ipcEventConfigErrors.value, [
        {
          'filename': '/home/user/.config/miracle-wm/config.yaml',
          'line': 12,
          'column': 3,
          'level': 'error',
          'message': 'Cannot find requested terminal program: notaterminal',
        },
        {
          'filename': '/home/user/.config/miracle-wm/config.yaml',
          'line': 4,
          'column': 1,
          'level': 'warning',
          'message': 'Unknown key',
        },
      ]);

      final configErrors = await event;
      expect(configErrors.hasProblems, isTrue);
      expect(configErrors.onlyErrors, hasLength(1));
      expect(configErrors.onlyWarnings, hasLength(1));
      expect(configErrors.errors.first.toString(), contains(':12:3: error:'));
    });

    test('delivers an empty config errors event', () async {
      final event = connection.configErrorEvents.first;

      miracle.pushEvent(IpcType.ipcEventConfigErrors.value, []);

      expect((await event).hasProblems, isFalse);
    });

    test('delivers plugin events per namespace', () async {
      final mine = connection.pluginEventsFor('my-plugin').first;

      miracle
        ..pushEvent(IpcType.ipcEventPlugin.value, {
          'plugin': 'other-plugin',
          'payload': {'ignored': true},
        })
        ..pushEvent(IpcType.ipcEventPlugin.value, {
          'plugin': 'my-plugin',
          'payload': {'state': 'connected', 'battery': 87},
        });

      final event = await mine;
      expect(event.plugin, 'my-plugin');
      expect(event.payloadObject, {'state': 'connected', 'battery': 87});
    });

    test('surfaces an event type it does not model as UnknownEvent', () async {
      final event = connection.whereType<UnknownEvent>().first;

      miracle.pushEvent(IpcType.ipcEventInput.value, {'change': 'added'});

      expect((await event).type, IpcType.ipcEventInput);
    });

    test('reports an unrecognized message instead of dropping it', () async {
      await connection.disconnect();
      connection = MiracleConnection();
      final unknown = <int>[];
      await connection.connect(
        socketPath: miracle.socketPath,
        onUnknownMessage: (type, payload) => unknown.add(type),
      );
      await miracle.waitForClients(1);

      miracle.pushRaw(0x80000099, '{}');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(unknown, [0x80000099]);
    });

    test('a malformed event does not tear the stream down', () async {
      final errors = <Object>[];
      connection.listen((_) {}, onError: errors.add);

      miracle.pushRaw(IpcType.ipcEventWorkspace.value, 'not json');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final next = connection.workspaceEvents.first;
      miracle.pushEvent(
          IpcType.ipcEventWorkspace.value, {'change': 'init', 'current': null});

      expect(errors, isNotEmpty);
      expect((await next).change, WorkspaceChange.init);
    });

    test('reassembles a message split across socket reads', () async {
      final event = connection.workspaceEvents.first;

      // Cut the message in the middle of its header, so that the first read
      // does not even carry a full frame.
      await miracle.pushEventInChunks(
        IpcType.ipcEventWorkspace.value,
        {'change': 'init'},
        splitAt: 9,
      );

      expect((await event).change, WorkspaceChange.init);
    });

    test('handles two messages arriving in a single read', () async {
      final events = connection.workspaceEvents.take(2).toList();

      miracle.pushEvents(IpcType.ipcEventWorkspace.value, [
        {'change': 'init'},
        {'change': 'empty'},
      ]);

      expect((await events).map((event) => event.change),
          [WorkspaceChange.init, WorkspaceChange.empty]);
    });
  });
}

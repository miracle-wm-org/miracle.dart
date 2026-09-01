import 'dart:convert';

import 'package:miracle/miracle.dart';
import 'package:test/test.dart';

/// The tree from <https://wiki.miracle-wm.org/develop/ipc/get_tree/>.
const String _documentedTree = '''
{
  "id": 0,
  "name": "root",
  "type": "root",
  "rect": {"x": 0, "y": 0, "width": 1280, "height": 1024},
  "nodes": [
    {
      "id": 101330841730944,
      "name": "unknown-1",
      "type": "output",
      "active": true,
      "adaptive_sync_status": false,
      "border": "none",
      "current_border_width": 0,
      "current_mode": {"height": 1024, "refresh": 60000.0, "width": 1280},
      "deco_rect": {"height": 0, "width": 0, "x": 0, "y": 0},
      "dpms": true,
      "focused": true,
      "geometry": {"height": 0, "width": 0, "x": 0, "y": 0},
      "layout": "output",
      "make": "Unknown",
      "model": "Unknown",
      "modes": [{"height": 1024, "refresh": 60000.0, "width": 1280}],
      "orientation": "none",
      "rect": {"height": 1024, "width": 1280, "x": 0, "y": 0},
      "scale": 1.0,
      "scale_filter": "linear",
      "serial": "Unknown",
      "transform": "normal",
      "urgent": false,
      "visible": true,
      "window_rect": {"height": 0, "width": 0, "x": 0, "y": 0},
      "nodes": [
        {
          "id": 101330847378496,
          "name": "1",
          "type": "workspace",
          "num": 1,
          "border": "none",
          "current_border_width": 0,
          "deco_rect": {"height": 0, "width": 0, "x": 0, "y": 0},
          "floating_nodes": [],
          "focused": false,
          "geometry": {"height": 0, "width": 0, "x": 0, "y": 0},
          "layout": "splith",
          "orientation": "none",
          "output": "unknown-1",
          "rect": {"height": 1014, "width": 1270, "x": 5, "y": 5},
          "urgent": false,
          "visible": true,
          "window": null,
          "window_rect": {"height": 0, "width": 0, "x": 0, "y": 0},
          "nodes": [
            {
              "id": 133916745441920,
              "name": "",
              "type": "con",
              "app_id": "kitty",
              "border": "normal",
              "current_border_width": 2,
              "deco_rect": {"height": 1014, "width": 1270, "x": 0, "y": 0},
              "floating_nodes": [],
              "focus": [],
              "focused": true,
              "fullscreen_mode": 0,
              "geometry": {"height": 1014, "width": 1270, "x": 0, "y": 0},
              "idle_inhibitors": {"application": "none", "user": "visible"},
              "inhibit_idle": false,
              "layout": "none",
              "nodes": [],
              "orientation": "none",
              "percent": 1.0,
              "pid": 15286,
              "rect": {"height": 1014, "width": 1270, "x": 5, "y": 5},
              "scratchpad_state": "none",
              "shell": "miracle-wm",
              "sticky": false,
              "urgent": false,
              "visible": true,
              "window": 133916745441920,
              "window_properties": {},
              "window_rect": {"height": 1010, "width": 1266, "x": 7, "y": 7}
            }
          ]
        }
      ]
    }
  ]
}
''';

void main() {
  late BaseNode tree;

  setUp(() {
    tree = BaseNode.fromJson(
        jsonDecode(_documentedTree) as Map<String, dynamic>);
  });

  test('parses the documented tree', () {
    expect(tree, isA<RootNode>());
    expect(tree.rect, const Rect(x: 0, y: 0, width: 1280, height: 1024));

    final output = tree.outputs.single;
    expect(output.name, 'unknown-1');
    expect(output.dpms, isTrue);
    expect(output.scale, 1.0);
    expect(output.layout, ContainerLayout.output);
    expect(output.transform, OutputTransform.normal);
    expect(output.currentMode?.refreshHz, 60);
    expect(output.modes.single.size, const Size(width: 1280, height: 1024));

    final workspace = tree.workspaces.single;
    expect(workspace.num, 1);
    expect(workspace.hasNumber, isTrue);
    expect(workspace.layout, ContainerLayout.splith);
    expect(workspace.output, 'unknown-1');

    final window = tree.windows.single;
    expect(window.appId, 'kitty');
    expect(window.pid, 15286);
    expect(window.border, BorderType.normal);
    expect(window.isFullscreen, isFalse);
    expect(window.isFloating, isFalse);
    expect(window.scratchpadState, ScratchpadState.none);
    expect(window.isOnScratchpad, isFalse);
    expect(window.idleInhibitors?.user, 'visible');
    expect(window.windowProperties.isEmpty, isTrue);
  });

  test('walks the tree depth first', () {
    expect(tree.walk().map((node) => node.type), [
      NodeType.root,
      NodeType.output,
      NodeType.workspace,
      NodeType.container,
    ]);
    expect(tree.descendants, hasLength(3));
  });

  test('finds nodes by id', () {
    expect(tree.findById(101330847378496), isA<WorkspaceNode>());
    expect(tree.findById(-1), isNull);
  });

  test('finds the focused node', () {
    // The output is focused too, but the deepest match wins by document
    // order only, so the shallowest focused node is reported first.
    expect(tree.focusedNode, isA<OutputNode>());
    expect(tree.workspaces.single.focusedNode, isA<ContainerNode>());
  });

  test('prints a readable tree', () {
    final printed = tree.toString();
    expect(printed, contains('[ROOT]'));
    expect(printed, contains('[OUTPUT]'));
    expect(printed, contains('[WORKSPACE]'));
    expect(printed, contains('app_id="kitty"'));
  });

  test('parses a floating container', () {
    final node = BaseNode.fromJson({
      'id': 1,
      'name': 'floater',
      'type': 'floating_con',
      'rect': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
    }) as ContainerNode;

    expect(node.type, NodeType.floatingContainer);
    expect(node.isFloating, isTrue);
    // Nothing else was reported, and nothing threw.
    expect(node.isWindow, isFalse);
    expect(node.idleInhibitors, isNull);
    expect(node.scratchpadState, isNull);
  });

  test('parses a split container that omits pid and app_id', () {
    final node = BaseNode.fromJson({
      'id': 2,
      'name': 'splith',
      'type': 'con',
      'layout': 'splith',
      'rect': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
      'idle_inhibitors': <String, dynamic>{},
      'window': null,
      'nodes': <dynamic>[],
    }) as ContainerNode;

    expect(node.pid, isNull);
    expect(node.appId, isNull);
    expect(node.isWindow, isFalse);
    expect(node.layout, ContainerLayout.splith);
  });

  test('reports urgency across the tree', () {
    // Nothing in the documented tree wants attention.
    expect(tree.isUrgent, isFalse);
    expect(tree.outputs.single.isUrgent, isFalse);
    expect(tree.workspaces.single.isUrgent, isFalse);
    expect(tree.urgentWindows, isEmpty);

    // The same tree with the window, and everything above it, urgent. miracle
    // propagates urgency up to the output when it builds the tree.
    final urgent =
        _documentedTree.replaceAll('"urgent": false', '"urgent": true');
    final urgentTree =
        BaseNode.fromJson(jsonDecode(urgent) as Map<String, dynamic>);

    // The root never carries the field, so it stays false.
    expect(urgentTree.isUrgent, isFalse);
    expect(urgentTree.outputs.single.isUrgent, isTrue);
    expect(urgentTree.workspaces.single.isUrgent, isTrue);
    expect(urgentTree.workspaces.single.urgent, isTrue);

    final window = urgentTree.urgentWindows.single;
    expect(window.appId, 'kitty');
    expect(window.urgent, isTrue);
    expect(window.isUrgent, isTrue);
  });

  test('treats an omitted urgent field as not urgent', () {
    final node = BaseNode.fromJson({
      'id': 3,
      'name': 'no-urgency',
      'type': 'con',
      'rect': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
    });

    expect(node.isUrgent, isFalse);
  });

  test('rejects a node whose type it cannot place', () {
    expect(
      () => BaseNode.fromJson({'id': 1, 'name': 'x', 'type': 'nonsense'}),
      throwsA(isA<Exception>()),
    );
  });
}

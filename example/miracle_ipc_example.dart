import 'package:miracle/miracle.dart';

void main() async {
  var connection = MiracleConnection();
  print('Connecting...');
  await connection.connect().then((_) {
    print('Connected!');
  }).catchError((e) {
    print('Error: $e');
  });

  print('\n=== Window Tree ===\n');
  final tree = await connection.getTree();
  print(tree);

  final version = await connection.getVersion();
  print(version);

  final modes = await connection.getBindingModes();
  print(modes);

  final bindingState = await connection.getBindingState();
  print(bindingState);

  final tick = await connection.sendTick();
  print(tick);

  // final workspaces = await connection.getWorkspaces();
  // for (var ws in workspaces) {
  //   print(
  //     'Workspace ${ws.num}: ${ws.name}, focused: ${ws.focused}, visible: ${ws.visible}, urgent: ${ws.urgent}, output: ${ws.output}, rect: (${ws.rect.x}, ${ws.rect.y}, ${ws.rect.width}, ${ws.rect.height})',
  //   );
  // }
  // await connection.subscribe([SubscribeEvent.workspace]).then((response) {
  //   if (response.success) {
  //     print('Subscribed successfully to workspace events.');
  //   } else {
  //     print('Failed to subscribe: ${response.error}');
  //   }
  // });
}

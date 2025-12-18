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

  final sync = await connection.sync();
  print(sync);

  // Listen for events
  connection.listen((event) {
    print('Received event: $event');
  });

  // Subscribe to workspace events
  final subscribeResponse =
      await connection.subscribe([SubscriptionType.workspace]);
  if (subscribeResponse.success) {
    print('Subscribed successfully to workspace events.');
  } else {
    print('Failed to subscribe: ${subscribeResponse.error}');
  }

  print('Listening for events (press Ctrl+C to exit)');

  // Keep the program running to receive events
  await Future.delayed(Duration(days: 1));
}

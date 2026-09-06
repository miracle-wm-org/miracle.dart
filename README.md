# miracle-ipc.dart
[![CI](https://github.com/miracle-wm-org/miracle.dart/actions/workflows/ci.yml/badge.svg)](https://github.com/miracle-wm-org/miracle.dart/actions/workflows/ci.yml)

A strongly-typed Dart API for interacting with the [miracle](https://miracle-wm.org)
tiling window manager from Dart and Flutter.

It covers all of [miracle's IPC protocol](https://wiki.miracle-wm.org/develop/ipc/).

## Installation

```yaml
dependencies:
  miracle: ^2.1.0
```

## Connecting

The socket path is read from `MIRACLESOCK`, falling back to `SWAYSOCK` and
then `I3SOCK`.

```dart
import 'package:miracle/miracle.dart';

final connection = MiracleConnection();
await connection.connect();
```

## Example

See [`example/miracle_ipc_example.dart`](example/miracle_ipc_example.dart) for
a tour of the whole API.

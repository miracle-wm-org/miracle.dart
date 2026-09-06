# miracle.dart
[![CI](https://github.com/miracle-wm-org/miracle.dart/actions/workflows/ci.yml/badge.svg)](https://github.com/miracle-wm-org/miracle.dart/actions/workflows/ci.yml)

A strongly-typed Dart API for interacting with the [miracle](https://miracle-wm.org)
tiling window manager from Dart and Flutter.

It covers two things:

- **IPC** — all of [miracle's IPC protocol](https://wiki.miracle-wm.org/develop/ipc/),
  for querying and driving a running compositor.
- **Configuration** — reading and writing miracle's configuration file, through
  the `libmiracle-wm-c` library that ships with miracle-wm.

## Installation

```yaml
dependencies:
  miracle: ^2.4.0
```

See [`example/miracle_ipc_example.dart`](example/miracle_ipc_example.dart) for examples of the IPC API.
See [`example/miracle_config_example.dart`](example/miracle_config_example.dart) for examples of the configuration API.

## Contributing

The FFI bindings in `lib/src/config/bindings.g.dart` are generated from the
vendored header in `third_party/miracle/`. Regenerate them with:

```sh
dart pub global activate ffigen 21.0.0
dart run tool/generate_bindings.dart            # from the pinned commit
dart run tool/generate_bindings.dart --local    # from /usr/include
```

CI regenerates from the pinned commit and fails if the result differs, so both
the header and the bindings are checked in deliberately.

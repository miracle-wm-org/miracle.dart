// Regenerates the FFI bindings in `lib/src/config/bindings.g.dart`.
//
// The header that the bindings are generated from is vendored into
// `third_party/miracle/` so that regeneration is reproducible and CI can prove
// the checked-in bindings still match it.
//
// Usage:
//   dart run tool/generate_bindings.dart              # from the pinned commit
//   dart run tool/generate_bindings.dart --ref develop
//   dart run tool/generate_bindings.dart --local      # from /usr/include
//
// `ffigen` is deliberately not a dev_dependency: it requires a far newer SDK
// than this package does, and adding it would raise the floor for every
// consumer to support a step almost nobody runs. It is activated globally
// instead, pinned to [_ffigenVersion].
import 'dart:io';

/// The `ffigen` version that the checked-in bindings were generated with.
const String _ffigenVersion = '21.0.0';

/// The upstream repository that the header is vendored from.
const String _repo = 'https://github.com/miracle-wm-org/miracle-wm';

/// The path to the header within [_repo].
const String _headerPath = 'miracle-wm-c/include/miracle/config.h';

/// Where a locally installed copy of the header lives.
const String _localHeader = '/usr/include/miracle/config.h';

/// The vendored copy that ffigen actually reads.
const String _vendoredHeader = 'third_party/miracle/config.h';

/// Records where [_vendoredHeader] came from.
const String _versionFile = 'third_party/miracle/VERSION';

Future<void> main(List<String> arguments) async {
  final local = arguments.contains('--local');
  final ref = _stringOption(arguments, '--ref');

  if (local && ref != null) {
    _fail('--local and --ref are mutually exclusive.');
  }

  if (!File('pubspec.yaml').existsSync()) {
    _fail('Run this from the root of the package.');
  }

  final pinned = _readVersionFile();

  if (local) {
    await _vendorFromDisk();
  } else {
    await _vendorFromUpstream(ref ?? pinned['commit'] ?? 'develop');
  }

  await _runFfigen();

  stdout.writeln('Wrote lib/src/config/bindings.g.dart.');
}

/// Copies the header off this machine, recording that the vendored copy is no
/// longer tied to a known upstream commit.
Future<void> _vendorFromDisk() async {
  final source = File(_localHeader);
  if (!source.existsSync()) {
    _fail('$_localHeader does not exist. Install miracle-wm, or drop --local.');
  }

  stdout.writeln('Vendoring $_localHeader.');
  source.copySync(_vendoredHeader);
  _writeVersionFile(ref: 'local', commit: 'unknown ($_localHeader)');
}

/// Fetches the header from [ref] upstream and resolves [ref] to a commit so the
/// vendored copy stays reproducible even when [ref] is a moving branch.
Future<void> _vendorFromUpstream(String ref) async {
  stdout.writeln('Fetching $_headerPath at $ref.');

  final raw = _repo.replaceFirst(
    'https://github.com',
    'https://raw.githubusercontent.com',
  );
  final header = await _get('$raw/$ref/$_headerPath');
  if (!header.contains('MIRACLE_WM_CONFIG_C_H')) {
    _fail('$ref does not look like a miracle config header.');
  }

  File(_vendoredHeader).writeAsStringSync(header);
  _writeVersionFile(ref: ref, commit: await _resolveCommit(ref));
}

/// Resolves [ref] to a full commit SHA, leaving it alone when it already is one.
Future<String> _resolveCommit(String ref) async {
  if (RegExp(r'^[0-9a-f]{40}$').hasMatch(ref)) return ref;

  final slug = Uri.parse(_repo).path;
  final body = await _get('https://api.github.com/repos$slug/commits/$ref');
  final sha = RegExp(r'"sha"\s*:\s*"([0-9a-f]{40})"').firstMatch(body);
  if (sha == null) _fail('Could not resolve $ref to a commit.');
  return sha.group(1)!;
}

Future<String> _get(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    // GitHub's API rejects requests that do not identify themselves.
    request.headers.set(HttpHeaders.userAgentHeader, 'miracle.dart-bindings');
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      _fail('GET $url failed with ${response.statusCode}.');
    }
    return body;
  } finally {
    client.close();
  }
}

/// Runs the globally activated `ffigen`, activating it first when it is absent
/// or pinned to a different version.
Future<void> _runFfigen() async {
  final installed = await Process.run('dart', ['pub', 'global', 'list']);
  if (!'${installed.stdout}'.contains('ffigen $_ffigenVersion')) {
    stdout.writeln('Activating ffigen $_ffigenVersion.');
    final activate = await Process.run(
      'dart',
      ['pub', 'global', 'activate', 'ffigen', _ffigenVersion],
    );
    if (activate.exitCode != 0) {
      _fail('Activating ffigen failed:\n${activate.stderr}');
    }
  }

  stdout.writeln('Running ffigen.');
  final result = await Process.run(
    'dart',
    ['pub', 'global', 'run', 'ffigen', '--config', 'ffigen.yaml'],
  );
  stdout.write(result.stdout);
  if (result.exitCode != 0) {
    _fail('ffigen failed:\n${result.stderr}');
  }
}

Map<String, String> _readVersionFile() {
  final file = File(_versionFile);
  if (!file.existsSync()) return const {};

  final values = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('#') || !line.contains('=')) continue;
    final split = line.indexOf('=');
    values[line.substring(0, split).trim()] = line.substring(split + 1).trim();
  }
  return values;
}

void _writeVersionFile({required String ref, required String commit}) {
  File(_versionFile).writeAsStringSync('''
# Provenance of config.h in this directory.
#
# Regenerate with: dart run tool/generate_bindings.dart
repo=$_repo
ref=$ref
commit=$commit
path=$_headerPath
''');
}

/// Reads `--name value` or `--name=value` from [arguments].
String? _stringOption(List<String> arguments, String name) {
  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (argument == name) {
      if (i + 1 >= arguments.length) _fail('$name needs a value.');
      return arguments[i + 1];
    }
    if (argument.startsWith('$name=')) {
      return argument.substring(name.length + 1);
    }
  }
  return null;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

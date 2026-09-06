part of 'miracle_config.dart';

/// The library names to try, most specific first.
///
/// The versioned soname is preferred so that an ABI bump surfaces as a clean
/// "not found" rather than as a mismatched-symbol crash at some later point.
const List<String> _libraryNames = <String>[
  'libmiracle-wm-c.so.0',
  'libmiracle-wm-c.so',
];

/// The directories searched when the bare library name does not resolve.
const List<String> _librarySearchPaths = <String>[
  '/usr/lib/x86_64-linux-gnu',
  '/usr/lib/aarch64-linux-gnu',
  '/usr/lib',
  '/usr/lib64',
  '/usr/local/lib',
  '/lib/x86_64-linux-gnu',
  '/lib',
  '/lib64',
];

MiracleConfigBindings? _bindings;
String? _loadFailure;
bool _loadAttempted = false;

/// Loads `libmiracle-wm-c` once, remembering either the bindings or why they
/// could not be produced.
void _ensureLoaded() {
  if (_loadAttempted) return;
  _loadAttempted = true;

  if (!Platform.isLinux) {
    _loadFailure =
        'miracle-wm is Linux-only; this is ${Platform.operatingSystem}.';
    return;
  }

  for (final name in _libraryNames) {
    // Bare first, so LD_LIBRARY_PATH and the normal loader search win.
    final library =
        _tryOpen(name) ??
        _librarySearchPaths
            .map((path) => _tryOpen('$path/$name'))
            .firstWhere((library) => library != null, orElse: () => null);
    if (library != null) {
      _bindings = MiracleConfigBindings(library);
      return;
    }
  }

  _loadFailure =
      'Could not load ${_libraryNames.join(' or ')}. Install miracle-wm '
      '(0.10 or newer), or add the library to LD_LIBRARY_PATH. Searched '
      '${_librarySearchPaths.join(', ')}.';
}

DynamicLibrary? _tryOpen(String path) {
  try {
    return DynamicLibrary.open(path);
  } on ArgumentError {
    return null;
  }
}

/// The loaded bindings, or a thrown [MiracleConfigException] explaining why
/// there are none.
MiracleConfigBindings get _native {
  _ensureLoaded();
  final bindings = _bindings;
  if (bindings == null) throw MiracleConfigException(_loadFailure!);
  return bindings;
}

/// Converts a C string to Dart, mapping `NULL` to `null`.
///
/// The returned pointers alias memory owned by the configuration, so callers
/// must convert eagerly rather than holding on to the pointer.
String? _toDartStringOrNull(Pointer<Char> pointer) =>
    pointer == nullptr ? null : pointer.cast<Utf8>().toDartString();

/// As [_toDartStringOrNull], but treats `NULL` as the empty string.
String _toDartString(Pointer<Char> pointer) =>
    _toDartStringOrNull(pointer) ?? '';

/// Runs [body] with [value] as a NUL-terminated C string, freeing it after.
///
/// A null [value] is passed through as `NULL`, which several of the setters
/// treat as "unset". Every C setter copies into a `std::string`, so freeing
/// immediately afterwards is safe.
T _withNativeString<T>(String? value, T Function(Pointer<Char>) body) {
  if (value == null) return body(nullptr);
  final native = value.toNativeUtf8();
  try {
    return body(native.cast<Char>());
  } finally {
    malloc.free(native);
  }
}

/// Runs [body] with each of [values] as a C string, freeing them after.
T _withNativeStrings<T>(
  List<String?> values,
  T Function(List<Pointer<Char>>) body,
) {
  final natives = <Pointer<Utf8>>[];
  try {
    for (final value in values) {
      natives.add(value == null ? nullptr : value.toNativeUtf8());
    }
    return body(natives.map((native) => native.cast<Char>()).toList());
  } finally {
    for (final native in natives) {
      if (native != nullptr) malloc.free(native);
    }
  }
}

/// Packs a set of modifiers into the bitmask the C API expects.
int _packModifiers(Set<Modifier> modifiers) =>
    modifiers.fold(0, (mask, modifier) => mask | modifier.value);

/// Unpacks the bitmask the C API returns into a set of modifiers.
Set<Modifier> _unpackModifiers(int mask) =>
    Modifier.values.where((m) => mask & m.value == m.value).toSet();

/// Throws unless [index] is a valid element index of a list of [length].
///
/// Several of the C functions index their vectors without a bounds check, so
/// an out-of-range index there is undefined behaviour rather than an error.
void _checkIndex(int index, int length, [String name = 'index']) {
  if (index < 0 || index >= length) {
    throw RangeError.index(index, Iterable<void>.generate(length), name);
  }
}

/// Whether two modifier sets hold the same modifiers.
bool _modifiersEqual(Set<Modifier> a, Set<Modifier> b) =>
    a.length == b.length && a.containsAll(b);

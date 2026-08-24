/// Internal, tolerant JSON coercion helpers.
///
/// miracle's IPC payloads are hand-rolled JSON and the exact set of keys
/// depends on which node/event produced them: split containers omit `pid` and
/// `app_id`, workspace events omit `current` on a `reload` change, `refresh`
/// is sometimes an `int` and sometimes a `double`, and so on.
///
/// Every model in this package decodes through these helpers so that a
/// surprising payload yields a sensible default instead of tearing down the
/// event stream with a `TypeError`.
library;

/// Reads [json] as a JSON object, falling back to an empty map.
Map<String, dynamic> asObject(Object? json) =>
    json is Map<String, dynamic> ? json : const <String, dynamic>{};

/// Reads [json] as a JSON object, or `null` when it is absent or not an object.
Map<String, dynamic>? asObjectOrNull(Object? json) =>
    json is Map<String, dynamic> ? json : null;

/// Reads [json] as a JSON list, falling back to an empty list.
List<dynamic> asList(Object? json) => json is List<dynamic> ? json : const [];

/// Reads [json] as a list of JSON objects, skipping any non-object entries.
List<Map<String, dynamic>> asObjectList(Object? json) =>
    asList(json).whereType<Map<String, dynamic>>().toList(growable: false);

/// Reads [json] as a list of strings, skipping any non-string entries.
List<String> asStringList(Object? json) =>
    asList(json).whereType<String>().toList(growable: false);

/// Reads [json] as an `int`, or `null` when it is absent or not numeric.
int? asIntOrNull(Object? json) {
  if (json is int) return json;
  if (json is num) return json.toInt();
  if (json is String) return int.tryParse(json);
  return null;
}

/// Reads [json] as an `int`, falling back to [fallback].
int asInt(Object? json, [int fallback = 0]) => asIntOrNull(json) ?? fallback;

/// Reads [json] as a `double`, or `null` when it is absent or not numeric.
double? asDoubleOrNull(Object? json) {
  if (json is double) return json;
  if (json is num) return json.toDouble();
  if (json is String) return double.tryParse(json);
  return null;
}

/// Reads [json] as a `double`, falling back to [fallback].
double asDouble(Object? json, [double fallback = 0]) =>
    asDoubleOrNull(json) ?? fallback;

/// Reads [json] as a `bool`, or `null` when it is absent or not a bool.
bool? asBoolOrNull(Object? json) => json is bool ? json : null;

/// Reads [json] as a `bool`, falling back to [fallback].
bool asBool(Object? json, [bool fallback = false]) =>
    asBoolOrNull(json) ?? fallback;

/// Reads [json] as a `String`, or `null` when it is absent or not a string.
String? asStringOrNull(Object? json) => json is String ? json : null;

/// Reads [json] as a `String`, falling back to [fallback].
String asString(Object? json, [String fallback = '']) =>
    asStringOrNull(json) ?? fallback;

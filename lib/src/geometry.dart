import 'json.dart';

/// A generic rectangle.
class Rect {
  /// The x coordinate.
  final int x;

  /// The y coordinate.
  final int y;

  /// The width.
  final int width;

  /// The height.
  final int height;

  const Rect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// A rectangle at the origin with no area.
  static const Rect zero = Rect(x: 0, y: 0, width: 0, height: 0);

  factory Rect.fromJson(Map<String, dynamic> json) {
    return Rect(
      x: asInt(json['x']),
      y: asInt(json['y']),
      width: asInt(json['width']),
      height: asInt(json['height']),
    );
  }

  /// Reads a rectangle from [json], falling back to [zero].
  static Rect parse(Object? json) {
    final object = asObjectOrNull(json);
    return object == null ? zero : Rect.fromJson(object);
  }

  /// Reads a rectangle from [json], or `null` when it is absent.
  static Rect? parseOrNull(Object? json) {
    final object = asObjectOrNull(json);
    return object == null ? null : Rect.fromJson(object);
  }

  /// The x coordinate of the right edge.
  int get right => x + width;

  /// The y coordinate of the bottom edge.
  int get bottom => y + height;

  /// The top left corner.
  Position get topLeft => Position(x: x, y: y);

  /// The size of this rectangle.
  Size get size => Size(width: width, height: height);

  /// Whether the point ([pointX], [pointY]) falls inside this rectangle.
  bool contains(int pointX, int pointY) =>
      pointX >= x && pointX < right && pointY >= y && pointY < bottom;

  /// Serializes this rectangle back to its IPC representation.
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  @override
  bool operator ==(Object other) =>
      other is Rect &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'Rect($x, $y, ${width}x$height)';
}

/// A point in global output coordinates.
class Position {
  /// The x coordinate.
  final int x;

  /// The y coordinate.
  final int y;

  const Position({required this.x, required this.y});

  /// The origin.
  static const Position zero = Position(x: 0, y: 0);

  factory Position.fromJson(Map<String, dynamic> json) =>
      Position(x: asInt(json['x']), y: asInt(json['y']));

  /// Reads a position from [json], falling back to [zero].
  static Position parse(Object? json) {
    final object = asObjectOrNull(json);
    return object == null ? zero : Position.fromJson(object);
  }

  /// Serializes this position back to its IPC representation.
  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Position($x, $y)';
}

/// A width and a height, in pixels.
class Size {
  /// The width.
  final int width;

  /// The height.
  final int height;

  const Size({required this.width, required this.height});

  /// A size with no area.
  static const Size zero = Size(width: 0, height: 0);

  factory Size.fromJson(Map<String, dynamic> json) =>
      Size(width: asInt(json['width']), height: asInt(json['height']));

  /// Reads a size from [json], or `null` when it is absent.
  static Size? parseOrNull(Object? json) {
    final object = asObjectOrNull(json);
    return object == null ? null : Size.fromJson(object);
  }

  /// Serializes this size back to its IPC representation.
  Map<String, dynamic> toJson() => {'width': width, 'height': height};

  @override
  bool operator ==(Object other) =>
      other is Size && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'Size(${width}x$height)';
}

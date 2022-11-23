import 'dart:io';

import 'case.dart';
import 'constant.dart';

String getClassName(
  Map<String, dynamic> data,
) {
  String? className = data[classKey];

  if (className == null) {
    stdout.writeln('Enter Serializable class name: ');
    className = stdin.readLineSync(retainNewlines: false);
  }

  if (className != null) return className;

  throw ArgumentError.notNull(
    '`$classKey` key is missing from json object',
  );
}

String generateJsonSerializableDataClass(
  Map<String, dynamic> data,
) {
  final String serializableClassName = getClassName(data);
  final fieldDeclarations = StringBuffer();
  final constructorParameterDeclarations = StringBuffer('\n');

  void addFieldDeclaration(MapEntry<String, dynamic> fieldEntry) {
    final code = generateFieldDeclaration(fieldEntry.key, fieldEntry.value);
    fieldDeclarations.writeln(code);
  }

  void addConstructorParameterDeclarations(
    MapEntry<String, dynamic> fieldEntry,
  ) {
    final code = generateConstructorParameterDeclaration(fieldEntry.key);
    constructorParameterDeclarations.writeln('$code,');
  }

  for (final fieldEntry in data.entries) {
    if (fieldEntry.key == classKey) continue;
    addFieldDeclaration(fieldEntry);
    addConstructorParameterDeclarations(fieldEntry);
  }

  return generateSerializableClassCode(
    serializableClassName,
    fieldDeclarations.toString(),
    constructorParameterDeclarations.toString(),
  );
}

String generateConstructorParameterDeclaration(String fieldKeyName) {
  final parameterName = lowerCamelCase(fieldKeyName);
  return '''  this.$parameterName''';
}

const _unknownType = 'UNKNOWN_DATA_TYPE';

int nonNullKeyCount(Map object) {
  return object.keys.where((key) => object[key] != null).length;
}

Object? getBestOf(Iterable values) {
  if (values.isEmpty) return null;
  var best = values.first;

  for (final it in values) {
    if (it is Map) {
      final key = it[classKey];
      if (key is String && key.isNotEmpty) {
        return it;
      }
    }
    if (best == null ||
        (best is Map &&
            it is Map &&
            nonNullKeyCount(best) < nonNullKeyCount(it))) {
      best = it;
    }
  }
  return best;
}

String guessDataType(
  Object? value, [
  String? fieldKeyName,
  bool changeUnknownWithDynamicJson = true,
]) {
  if (value is String) {
    return 'String';
  } else if (value is int || value is double) {
    return 'num';
  } else if (value is bool) {
    return 'bool';
  } else if (value is List) {
    String tDataType = _unknownType;
    if (value.isNotEmpty) {
      tDataType = guessDataType(getBestOf(value));
    }
    return 'List<$tDataType>';
  } else if (value == null) {
    return changeUnknownWithDynamicJson ? 'DynamicJson' : 'dynamic';
  } else if (value is Map) {
    final className = value[classKey];
    if (className is String && className.isNotEmpty) {
      return className;
    }
  }
  return 'UNKNOWN_DATA_TYPE';
}

String typed(String dataType, [bool makeNullable = true]) {
  if (dataType.isEmpty) {
    return '';
  } else if (dataType == 'dynamic' || !makeNullable) {
    return ' $dataType';
  } else {
    return ' $dataType?';
  }
}

String generateFieldDeclaration(
  String fieldKeyName,
  Object? fieldValue,
) {
  final fieldVariableName = lowerCamelCase(fieldKeyName);
  final fieldDataType = typed(guessDataType(fieldValue, fieldKeyName));

  return '''  @JsonKey(name: '$fieldKeyName')
  final$fieldDataType $fieldVariableName;''';
}

String generateSerializableClassCode(
  String serializableClassName,
  String fieldDeclarations,
  String constructorParameterDeclarations,
) {
  return '''@JsonSerializable()
class $serializableClassName {
$fieldDeclarations

  const $serializableClassName($constructorParameterDeclarations);

  factory $serializableClassName.fromJson(Map<String, dynamic> json) =>
      _\$${serializableClassName}FromJson(json);

  Map<String, dynamic> toJson() => _\$${serializableClassName}ToJson(this);
}
''';
}

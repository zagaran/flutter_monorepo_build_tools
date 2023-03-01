import 'package:yaml/yaml.dart';

extension YamlMapJsonParsing on YamlMap {
  Map<String, dynamic> toJson() {
    return value
        .map((key, value) => MapEntry(key.toString(), convertToJson(value)));
  }
}

extension YamlListJsonParsing on YamlList {
  List<dynamic> toJson() {
    return value.map((element) => convertToJson(element)).toList();
  }
}

dynamic convertToJson(dynamic value) {
  switch (value.runtimeType) {
    case YamlMap:
      return (value as YamlMap).toJson();
    case YamlList:
      return (value as YamlList).toJson();
    case YamlScalar:
      return convertToJson((value as YamlScalar).value);
    case int:
    case bool:
    case double:
    case num:
    case String:
      return value;
    default:
      return value.toString();
  }
}

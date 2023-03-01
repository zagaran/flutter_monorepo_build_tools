import 'package:json2yaml/json2yaml.dart';

String convertToYaml(Map<String, dynamic> json) => json2yaml(
      json,
      yamlStyle: YamlStyle.pubspecYaml,
    );

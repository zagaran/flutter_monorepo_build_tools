class BooleanParameterModel {
  final bool defaultValue;
  BooleanParameterModel({this.defaultValue = false});

  String get type => 'boolean';

  Map<String, dynamic> toJson() => {
        'type': type,
        'default': defaultValue,
      };

  factory BooleanParameterModel.fromJson(Map<String, dynamic> json) =>
      BooleanParameterModel(
        defaultValue: json['default'] as bool,
      );
}

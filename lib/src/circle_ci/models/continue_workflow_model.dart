class WorkflowModel {
  dynamic when;
  final List<dynamic> jobs;

  WorkflowModel({
    required this.when,
    this.jobs = const [],
  });

  factory WorkflowModel.fromJson(Map<String, dynamic> json) {
    return WorkflowModel(
      when: json['when'] is String
          ? json['when']
          : WhenModel.fromJson(json['when']),
      jobs: json['jobs'],
    );
  }

  Map<String, dynamic> toJson() => {
        'when': when is String
            ? when
            : when is WhenModel
                ? when.toJson()
                : when.toString(),
        'jobs': jobs,
      };
}

class WhenModel {
  final List<String> or;
  final List<dynamic> and;

  WhenModel({this.or = const <String>[], this.and = const []});

  factory WhenModel.fromJson(Map<String, dynamic> json) {
    List<String> or;
    if (json['or'] != null && json['or'] is List) {
      or = (json['or'] as List<dynamic>).map((e) => e.toString()).toList();
    } else {
      or = <String>[];
    }
    List<dynamic> and = json['and'] ??= <dynamic>[];
    return WhenModel(or: or, and: and);
  }

  Map<String, dynamic> toJson() {
    if (and.isNotEmpty && or.isNotEmpty) {
      return {
        'and': [
          {'or': or},
          {'and': and},
        ],
      };
    } else if (and.isNotEmpty) {
      return {
        'and': and,
      };
    } else {
      return {
        'or': or,
      };
    }
  }

  void setOrParameters(List<String> parameters) {
    or.clear();
    Iterable<String> newParameters = parameters
        .map((e) => '$parameterOpening $parameterPrefix$e $parameterClosing');
    or.addAll(newParameters);
  }
}

const String parameterOpening = '<<';
const String parameterClosing = '>>';
const String parameterPrefix = 'pipeline.parameters.';

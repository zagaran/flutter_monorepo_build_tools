import 'job_model.dart';

class WhenModel {
  final List<String> or;
  final List<dynamic> and;
  // if a single parameter is sufficient, use 'identity'; otherwise, it should
  // be null
  final String? identity;

  WhenModel({this.or = const <String>[], this.and = const [], this.identity});

  factory WhenModel.identity(String value) {
    return WhenModel(identity: value);
  }

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
    if (identity != null) {
      return {
        'or': [identity],
      };
    }
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

class WorkflowModel {
  List<WorkflowJob>? jobs;
  late String name;
  WhenModel? when;

  WorkflowModel({
    this.jobs,
    this.when,
    this.name = '',
  });

  WorkflowModel.fromJson(Map<String, dynamic> json) {
    if (json['jobs'] != null) {
      jobs = WorkflowJob.fromJsonList(json['jobs']);
    }
    if (json['when'] != null) {
      if (json['when'] is WhenModel) {
        when = json['when'];
      } else if (json['when'] is String) {
        when = WhenModel.identity(json['when']);
      } else {
        when = WhenModel.fromJson(json['when']);
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (jobs != null) {
      data['jobs'] = jobs!.map((j) => j.toYaml());
    }
    if (when != null) {
      data['when'] = when is String
          ? [when]
          : when is WhenModel
              ? when!.toJson()
              : when.toString();
    }
    return data;
  }
}

import 'package:flutter_monorepo_build_tools/src/circle_ci/models/job_model.dart';

class AlwaysRunModel {
  List<JobModel>? jobs;

  AlwaysRunModel({this.jobs});

  AlwaysRunModel.fromJson(Map<String, dynamic> json) {
    if (json['jobs'] != null) {
      jobs = <JobModel>[];
      json['jobs'].forEach((v) {
        jobs!.add(JobModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (jobs != null) {
      data['jobs'] = jobs!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

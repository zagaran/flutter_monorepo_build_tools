import 'package:monorepo_build_tool/src/circle_ci/models/path_filtering_filter_model.dart';

class JobModel {
  PathFilteringFilterModel? pathFilteringFilter;

  JobModel({this.pathFilteringFilter});

  JobModel.fromJson(Map<String, dynamic> json) {
    pathFilteringFilter = json['path-filtering/filter'] != null
        ? PathFilteringFilterModel.fromJson(json['path-filtering/filter'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (pathFilteringFilter != null) {
      data['path-filtering/filter'] = pathFilteringFilter!.toJson();
    }
    return data;
  }
}

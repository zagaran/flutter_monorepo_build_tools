class WorkflowJob {
  Map<String, dynamic>? params;
  late String key;
  WorkflowJob({this.params, this.key = ''});

  WorkflowJob.fromJson(Map<String, dynamic> json) {
    params = json;
  }

  dynamic toYaml() {
    if (params != null) {
      return toJson();
    }
    return key;
  }

  Map<String, dynamic> toJson() {
    return {key: params};
  }

  static List<WorkflowJob> fromJsonList(dynamic jsonList) {
    return jsonList
        .map<WorkflowJob>((m) => m is Map
            ? (WorkflowJob.fromJson(m.values.first)..key = m.keys.first)
            : WorkflowJob(key: m))
        .toList();
  }
}

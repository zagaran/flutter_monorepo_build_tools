class PathFilteringFilterModel {
  String? name;
  String? mapping;
  String? baseRevision;
  String? configPath;

  PathFilteringFilterModel(
      {this.name, this.mapping, this.baseRevision, this.configPath});

  PathFilteringFilterModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    mapping = json['mapping'];
    baseRevision = json['base-revision'];
    configPath = json['config-path'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['mapping'] = mapping;
    data['base-revision'] = baseRevision;
    data['config-path'] = configPath;
    return data;
  }
}

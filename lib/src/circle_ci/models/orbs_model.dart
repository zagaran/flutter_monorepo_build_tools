class OrbsModel {
  String? pathFiltering;

  OrbsModel({this.pathFiltering});

  OrbsModel.fromJson(Map<String, dynamic> json) {
    pathFiltering = json['path-filtering'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['path-filtering'] = pathFiltering;
    return data;
  }
}

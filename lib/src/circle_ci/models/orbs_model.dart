class OrbsModel {
  String? pathFiltering;
  String? continuation;

  OrbsModel({this.pathFiltering, this.continuation});

  OrbsModel.fromJson(Map<String, dynamic> json) {
    pathFiltering = json['path-filtering'];
    continuation = json['continuation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['path-filtering'] = pathFiltering;
    data['continuation'] = continuation;
    return data;
  }
}

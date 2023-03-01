// {RelativePackagePath}/.* {PackageName}_updated true
class CircleCiUpdateMappingModel {
  final String relativePackagePath;
  final String packageName;
  CircleCiUpdateMappingModel({
    required this.relativePackagePath,
    required this.packageName,
  });

  factory CircleCiUpdateMappingModel.createRaw(String mappingLine) {
    final List<String> splitLine = mappingLine.split(' ');
    final List<String> packageNameUpdatedSplit = splitLine[1].split('_');
    StringBuffer packageNameBuffer = StringBuffer();
    for (int i = 0; i < packageNameUpdatedSplit.length - 1; i++) {
      packageNameBuffer.write('${packageNameUpdatedSplit[i]}_');
    }
    return CircleCiUpdateMappingModel(
      relativePackagePath: splitLine[0].replaceAll('/.*', ''),
      packageName: packageNameBuffer.toString().substring(
            0,
            packageNameBuffer.length - 1,
          ),
    );
  }

  @override
  String toString() {
    return "$relativePackagePath/.* ${packageName}_updated true";
  }

  String get parameterName {
    return '${packageName}_updated';
  }
}

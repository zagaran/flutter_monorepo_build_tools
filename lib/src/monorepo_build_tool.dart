import 'dart:collection';
import 'dart:io';

import 'package:flutter_monorepo_build_tools/src/dart_utils/pubspec_methods.dart';
import 'package:flutter_monorepo_build_tools/src/graph/adjacency_list.dart';
import 'package:flutter_monorepo_build_tools/src/graph/graph.dart';
import 'package:flutter_monorepo_build_tools/src/graph/graph_ext.dart';
import 'package:flutter_monorepo_build_tools/src/graph/vertex.dart';
import 'package:flutter_monorepo_build_tools/src/update_manager/update_manager.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class MonorepoBuildTool {
  final Directory origin;
  final String packagesPath;
  final bool isSamePackagesDir;
  final Graph<Directory> graph = AdjacencyList<Directory>();
  final UpdateManager updateManager;
  final bool verboseOutput;

  MonorepoBuildTool({
    required this.origin,
    this.packagesPath = 'packages',
    this.isSamePackagesDir = false,
    required this.updateManager,
    required this.verboseOutput,
  });

  Future<void> init() async {
    final Queue<Directory> queue = Queue();
    queue.add(origin);
    graph.createVertex(origin);
    while (queue.isNotEmpty) {
      final Directory file = queue.removeFirst();
      Vertex<Directory> vertex = graph.getOrCreateVertex(
        file,
        (otherFile) => otherFile.path == file.path,
      );

      // Pubspec stuff
      final File pubspecFile = File(generatePubspecPath(file.path));
      final content = await pubspecFile.readAsString();
      YamlMap yamlFileContents = await loadYaml(
        content,
        sourceUrl: pubspecFile.uri,
      );
      YamlMap dependencies = yamlFileContents['dependencies'] as YamlMap;
      List<String> localDependencies = dependencies.entries
          .where((element) => element.value is YamlMap)
          .where(
              (element) => ((element).value as YamlMap).keys.contains('path'))
          .map((e) => (e.value as YamlMap)['path'] as String)
          .toList();

      for (String path in localDependencies) {
        final String packagePath;
        if (!path.contains(packagesPath)) {
          packagePath = path.replaceAll('../', '$packagesPath/');
        } else {
          packagePath = path;
        }
        final Directory dependencyFile =
            locateDependencyFile(isSamePackagesDir, origin, packagePath);
        queue.add(dependencyFile);
        graph.addEdge(
            vertex,
            graph.getOrCreateVertex(
              dependencyFile,
              (otherFile) => otherFile.path == dependencyFile.path,
            ));
      }
    }
  }

  Directory locateDependencyFile(
    bool isSamePackagesDir,
    Directory origin,
    String packagePath,
  ) {
    if (isSamePackagesDir) {
      List<String> splitPath = p.split(origin.path);
      String newPath = p.join(
        // if packages are in the same directory, cut off the last element
        splitPath.sublist(0, splitPath.length - 2).join("/"),
        packagePath,
      );
      return Directory(newPath);
    } else {
      return Directory('${origin.path}/$packagePath');
    }
  }

  Future<void> assignNewCircleCiDependencies() async {
    await updateManager.runUpdate(
      graph,
    );
  }
}

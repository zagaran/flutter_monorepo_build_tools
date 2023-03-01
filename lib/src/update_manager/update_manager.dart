import 'dart:io';

import 'package:monorepo_build_tool/src/graph/graph.dart';

abstract class UpdateManager {
  Future<void> runUpdate(Graph<Directory> dependencyGraph);
}

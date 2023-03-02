import 'dart:io';

import 'package:flutter_monorepo_build_tools/src/graph/graph.dart';

abstract class UpdateManager {
  Future<void> runUpdate(Graph<Directory> dependencyGraph);
}

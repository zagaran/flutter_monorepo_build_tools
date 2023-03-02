import 'package:flutter_monorepo_build_tools/src/graph/graph.dart';
import 'package:flutter_monorepo_build_tools/src/graph/vertex.dart';

extension GraphExtensions<E> on Graph<E> {
  Vertex<E> getOrCreateVertex(E data, bool Function(E data) predicate) =>
      vertices.firstWhere(
        (element) => predicate(element.data),
        orElse: () => createVertex(data),
      );
}

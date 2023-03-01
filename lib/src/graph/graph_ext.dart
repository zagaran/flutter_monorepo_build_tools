import 'package:monorepo_build_tool/src/graph/graph.dart';
import 'package:monorepo_build_tool/src/graph/vertex.dart';

extension GraphExtensions<E> on Graph<E> {
  Vertex<E> getOrCreateVertex(E data, bool Function(E data) predicate) =>
      vertices.firstWhere(
        (element) => predicate(element.data),
        orElse: () => createVertex(data),
      );
}

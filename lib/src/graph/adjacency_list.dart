import 'package:monorepo_build_tool/src/graph/edge.dart';
import 'package:monorepo_build_tool/src/graph/edge_type.dart';
import 'package:monorepo_build_tool/src/graph/graph.dart';
import 'package:monorepo_build_tool/src/graph/vertex.dart';

///
/// Implementation inspired by
/// https://www.kodeco.com/books/data-structures-algorithms-in-dart/v1.0/chapters/20-graphs
///

class AdjacencyList<E> implements Graph<E> {
  final Map<Vertex<E>, List<Edge<E>>> _connections = {};
  var _nextIndex = 0;

  @override
  Iterable<Vertex<E>> get vertices => _connections.keys;

  @override
  void addEdge(Vertex<E> source, Vertex<E> destination,
      {EdgeType edgeType = EdgeType.directed, double? weight = 1}) {
    _connections[source]?.add(
      Edge<E>(source, destination, weight),
    );
    if (edgeType == EdgeType.undirected) {
      _connections[destination]?.add(
        Edge<E>(destination, source, weight),
      );
    }
  }

  @override
  Vertex<E> createVertex(E data) {
    final vertex = Vertex(
      index: _nextIndex,
      data: data,
    );
    _nextIndex++;
    _connections[vertex] = [];
    return vertex;
  }

  @override
  List<Edge<E>> edges(Vertex<E> source) {
    return _connections[source] ?? [];
  }

  @override
  double? weight(Vertex<E> source, Vertex<E> destination) {
    final match = edges(source).where((edge) {
      return edge.destination == destination;
    });
    if (match.isEmpty) return null;
    return match.first.weight;
  }

  @override
  String toString() {
    final result = StringBuffer();
    // 1
    _connections.forEach((vertex, edges) {
      // 2
      final destinations = edges.map((edge) {
        return edge.destination;
      }).join(', ');
      // 3
      result.writeln('$vertex --> $destinations');
    });
    return result.toString();
  }
}

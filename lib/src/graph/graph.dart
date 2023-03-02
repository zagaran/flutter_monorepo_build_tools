import 'package:flutter_monorepo_build_tools/src/graph/edge.dart';
import 'package:flutter_monorepo_build_tools/src/graph/edge_type.dart';
import 'package:flutter_monorepo_build_tools/src/graph/vertex.dart';

abstract class Graph<E> {
  Iterable<Vertex<E>> get vertices;

  Vertex<E> createVertex(E data);

  void addEdge(
    Vertex<E> source,
    Vertex<E> destination, {
    EdgeType edgeType = EdgeType.directed,
    double? weight = 1,
  });

  List<Edge<E>> edges(Vertex<E> source);

  double? weight(
    Vertex<E> source,
    Vertex<E> destination,
  );
}

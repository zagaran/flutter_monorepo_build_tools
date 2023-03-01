import 'package:monorepo_build_tool/src/graph/vertex.dart';

class Edge<T> {
  const Edge(
    this.source,
    this.destination, [
    this.weight,
  ]);

  final Vertex<T> source;
  final Vertex<T> destination;
  final double? weight;
}

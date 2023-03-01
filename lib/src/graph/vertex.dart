class Vertex<T> {
  const Vertex({
    required this.index,
    required this.data,
  });

  final int index;
  final T data;

  @override
  String toString() => data.toString();
}

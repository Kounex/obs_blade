/// utils should be used for generic stuff which can be useful from everywhere in the
/// app. This example is a extension method for the List type so every List object can
/// use this new method. Another examples would be static functions doing stuff you would
/// do on several places, so summarize them in a util class!
extension ListStuff<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T f(E element, int index)) sync* {
    var index = 0;

    for (final item in this) {
      yield f(item, index);
      index = index + 1;
    }
  }
}

/// Interface which serves as an abstraction layer for persistance tasks.
/// Every class which implements this has to provide a [load] and [save] function
/// which is what we actually need and do (for now) for this task. The actual
/// implementation can then be handeled individually (right now hive)
abstract class Persistance<T> {
  /// Persist [item], should return a bool to indicate if the task was successful
  bool save(T item);

  /// Load items as List
  List<T> load();
}

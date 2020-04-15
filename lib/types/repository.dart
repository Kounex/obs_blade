/// Named as an action since it provides methods
mixin Notifier {
  void notifyAll() {
    print('Notifying everyone...');
  }
}

extension ImprovedString on String {
  String add(String text) => this + text;
}

abstract class Repository with Notifier {
  void loadData() {
    print('Very'.add(' cool'));
  }
}

class ExtendedRepository extends Repository {
  void anotherLoadData() {
    print('Also loading data...');
    this.notifyAll();
  }
}

class ImplementedRepository implements Repository {
  @override
  void loadData() {
    print('Cooler loading data...');
  }

  @override
  void notifyAll() {
    // TODO: implement notifyAll
  }
}

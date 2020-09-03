import 'package:mobx/mobx.dart';

part 'intro.g.dart';

class IntroStore = _IntroStore with _$IntroStore;

abstract class _IntroStore with Store {
  @observable
  int currentPage = 0;

  @action
  void setCurrentPage(int currentPage) => this.currentPage = currentPage;
}

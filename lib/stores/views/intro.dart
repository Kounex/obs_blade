import 'package:mobx/mobx.dart';

part 'intro.g.dart';

class IntroStore = _IntroStore with _$IntroStore;

const int kSecondsToLockSlide = 5;

abstract class _IntroStore with Store {
  @observable
  int currentPage = 0;

  @observable
  bool lockedOnSlide = false;

  @observable
  int slideLockSecondsLeft = kSecondsToLockSlide;

  @action
  void setCurrentPage(int currentPage) => this.currentPage = currentPage;

  @action
  void setLockedOnSlide(bool lockedOnSlide, [int? secondsToLockSlide]) {
    this.slideLockSecondsLeft = secondsToLockSlide ?? kSecondsToLockSlide;
    this.lockedOnSlide = lockedOnSlide;
  }
}

import 'package:mobx/mobx.dart';

part 'intro.g.dart';

enum IntroStage {
  GettingStarted,
  VersionSelection,
  TwentyEightParty,
  InstallationSlides,
}

class IntroStore = _IntroStore with _$IntroStore;

const int kSecondsToLockSlide = 5;

abstract class _IntroStore with Store {
  @observable
  IntroStage stage = IntroStage.GettingStarted;

  @observable
  int currentPage = 0;

  @observable
  bool lockedOnSlide = false;

  int slideLockSeconds = kSecondsToLockSlide;

  @action
  void setStage(IntroStage stage) => this.stage = stage;

  @action
  void setCurrentPage(int currentPage) => this.currentPage = currentPage;

  @action
  void setLockedOnSlide(bool lockedOnSlide, [int? secondsToLockSlide]) {
    this.slideLockSeconds = secondsToLockSlide ?? kSecondsToLockSlide;
    this.lockedOnSlide = lockedOnSlide;
  }
}

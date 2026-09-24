// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combined_chat.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CombinedChatStore on _CombinedChatStore, Store {
  Computed<List<CombinedSource>>? _$mySourcesComputed;

  @override
  List<CombinedSource> get mySources =>
      (_$mySourcesComputed ??= Computed<List<CombinedSource>>(
        () => super.mySources,
        name: '_CombinedChatStore.mySources',
      )).value;
  Computed<List<CombinedSource>>? _$availableSourcesComputed;

  @override
  List<CombinedSource> get availableSources =>
      (_$availableSourcesComputed ??= Computed<List<CombinedSource>>(
        () => super.availableSources,
        name: '_CombinedChatStore.availableSources',
      )).value;
  Computed<Map<ChatType, CombinedSourceStatus>>? _$sourceStatusComputed;

  @override
  Map<ChatType, CombinedSourceStatus> get sourceStatus =>
      (_$sourceStatusComputed ??= Computed<Map<ChatType, CombinedSourceStatus>>(
        () => super.sourceStatus,
        name: '_CombinedChatStore.sourceStatus',
      )).value;
  Computed<List<CombinedItem>>? _$timelineComputed;

  @override
  List<CombinedItem> get timeline =>
      (_$timelineComputed ??= Computed<List<CombinedItem>>(
        () => super.timeline,
        name: '_CombinedChatStore.timeline',
      )).value;

  late final _$activeAtom = Atom(
    name: '_CombinedChatStore.active',
    context: context,
  );

  @override
  bool get active {
    _$activeAtom.reportRead();
    return super.active;
  }

  @override
  set active(bool value) {
    _$activeAtom.reportWrite(value, super.active, () {
      super.active = value;
    });
  }

  late final _$disabledPlatformsAtom = Atom(
    name: '_CombinedChatStore.disabledPlatforms',
    context: context,
  );

  @override
  ObservableSet<ChatType> get disabledPlatforms {
    _$disabledPlatformsAtom.reportRead();
    return super.disabledPlatforms;
  }

  @override
  set disabledPlatforms(ObservableSet<ChatType> value) {
    _$disabledPlatformsAtom.reportWrite(value, super.disabledPlatforms, () {
      super.disabledPlatforms = value;
    });
  }

  late final _$activateAsyncAction = AsyncAction(
    '_CombinedChatStore.activate',
    context: context,
  );

  @override
  Future<void> activate() {
    return _$activateAsyncAction.run(() => super.activate());
  }

  late final _$deactivateAsyncAction = AsyncAction(
    '_CombinedChatStore.deactivate',
    context: context,
  );

  @override
  Future<void> deactivate() {
    return _$deactivateAsyncAction.run(() => super.deactivate());
  }

  late final _$setPlatformEnabledAsyncAction = AsyncAction(
    '_CombinedChatStore.setPlatformEnabled',
    context: context,
  );

  @override
  Future<void> setPlatformEnabled(ChatType platform, bool enabled) {
    return _$setPlatformEnabledAsyncAction.run(
      () => super.setPlatformEnabled(platform, enabled),
    );
  }

  @override
  String toString() {
    return '''
active: ${active},
disabledPlatforms: ${disabledPlatforms},
mySources: ${mySources},
availableSources: ${availableSources},
sourceStatus: ${sourceStatus},
timeline: ${timeline}
    ''';
  }
}

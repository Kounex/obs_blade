import 'package:get_it/get_it.dart';

/// Whether [T]'s lazy singleton exists already - never creates it.
bool lazySingletonCreated<T extends Object>() {
  final getIt = GetIt.instance;
  if (!getIt.isRegistered<T>()) return false;
  try {
    return getIt.checkLazySingletonInstanceExists<T>();
  } on StateError {
    /// Registered as a plain singleton (tests) - it exists
    return true;
  }
}

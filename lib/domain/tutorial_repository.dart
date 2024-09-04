import 'package:flutter/material.dart';
import 'package:tutorial_system/tutorial_system.dart';

/// A repository class for managing tutorial-related data and functions.
///
/// This class stores and provides access to various components needed for tutorials,
/// including widget keys, conditions, contexts, and tutorial containers.
class TutorialRepository {
  /// The global navigator key used for navigation in the app.
  final GlobalKey<NavigatorState> globalNavigatorKey;

  /// A map of tutorial types to their corresponding [Tutorial] instances.
  final Map<Type, Tutorial> _tutorialContainers;

  /// A map of [TutorialID]s to their corresponding [GlobalKey]s.
  final Map<TutorialID, GlobalKey> _keyMap;

  /// A map of [TutorialID]s to their corresponding condition functions.
  final Map<TutorialID, Future<bool> Function(Duration)> _conditionMap;

  /// A map of [TutorialID]s to their corresponding [BuildContext]s.
  final Map<TutorialID, BuildContext> _contextMap;

  /// Creates a [TutorialRepository] with the given [globalNavigatorKey] and optional parameters.
  ///
  /// [tutorialContainers], [keyMap], [conditionMap], and [contextMap] can be provided
  /// to initialize the repository with existing data.
  TutorialRepository(this.globalNavigatorKey,
      {List<Tutorial>? tutorialContainers,
      Map<TutorialID, GlobalKey>? keyMap,
      Map<TutorialID, Future<bool> Function(Duration)>? conditionMap,
      Map<TutorialID, BuildContext>? contextMap})
      : _tutorialContainers = _getTypedMap(tutorialContainers),
        _keyMap = keyMap ?? {},
        _conditionMap = conditionMap ?? {},
        _contextMap = contextMap ?? {};

  static Map<Type, Tutorial> _getTypedMap(List<Tutorial>? containers) {
    final Map<Type, Tutorial> result = {};
    for (Tutorial tutorialContainer in containers ?? []) {
      result[tutorialContainer.runtimeType] = tutorialContainer;
    }
    return result;
  }

  /// Adds tutorial containers dynamically even after the [TutorialRepository] was created
  void addTutorialContainers(List<Tutorial> containers) {
    final Map<Type, Tutorial> typedMap = _getTypedMap(containers);
    _tutorialContainers.addAll(typedMap);
  }

  /// Calls the registration function for a specific tutorial type.
  ///
  /// [tutorialType] is the type of the tutorial to register.
  /// [caller] is the object calling the registration function.
  /// [state] is an optional [State] object that can be passed to the registration function.
  void callRegistrationFunction({required Type tutorialType, required dynamic caller, State? state}) {
    Tutorial? tutorialContainer = _tutorialContainers[tutorialType];
    if (tutorialContainer != null) {
      tutorialContainer.registrationFunction(this, caller, state: state);
    }
  }

  /// Registers a [GlobalKey] for a specific [TutorialID].
  void registerKey(TutorialID widgetID, GlobalKey? key) {
    if (key != null) {
      _keyMap[widgetID] = key;
    }
  }

  /// Registers multiple [GlobalKey]s at once.
  void registerKeys(Map<TutorialID, GlobalKey> keys) {
    _keyMap.addAll(keys);
  }

  /// Removes a [GlobalKey] for a specific [TutorialID].
  void removeKey(TutorialID widgetID) {
    _keyMap.remove(widgetID);
  }

  /// Retrieves a [GlobalKey] for a specific [TutorialID].
  GlobalKey? getKey(TutorialID widgetID) {
    return _keyMap[widgetID];
  }

  /// Registers a condition function for a specific [TutorialID].
  void registerCondition(TutorialID conditionID, Future<bool> Function(Duration timeout) condition) {
    _conditionMap[conditionID] = condition;
  }

  /// Registers multiple condition functions at once.
  void registerConditions(Map<TutorialID, Future<bool> Function(Duration timeout)> conditions) {
    _conditionMap.addAll(conditions);
  }

  /// Removes a condition function for a specific [TutorialID].
  void removeCondition(TutorialID conditionID) {
    _conditionMap.remove(conditionID);
  }

  /// Retrieves a condition function for a specific [TutorialID].
  Future<bool> Function(Duration)? getCondition(TutorialID conditionID) {
    return _conditionMap[conditionID];
  }

  /// Registers a [BuildContext] for a specific [TutorialID].
  void registerContext(TutorialID contextID, BuildContext? buildContext) {
    if (buildContext != null) {
      _contextMap[contextID] = buildContext;
    }
  }

  /// Registers multiple [BuildContext]s at once.
  void registerContexts(Map<TutorialID, BuildContext> contexts) {
    _contextMap.addAll(contexts);
  }

  /// Removes a [BuildContext] for a specific [TutorialID].
  void removeContext(TutorialID contextID) {
    _contextMap.remove(contextID);
  }

  /// Retrieves a [BuildContext] for a specific [TutorialID].
  BuildContext? getContext(TutorialID contextID) {
    return _contextMap[contextID];
  }

  /// Returns a copy of the registered tutorials
  List<Tutorial> getTutorials() {
    return List.from(_tutorialContainers.values);
  }

  /// Returns a copy of the internal key map.
  Map<TutorialID, GlobalKey> getKeyMap() {
    return Map.from(_keyMap);
  }

  /// Returns a copy of the internal condition map.
  Map<TutorialID, bool Function()> getConditionMap() {
    return Map.from(_conditionMap);
  }

  /// Returns a copy of the internal context map.
  Map<TutorialID, BuildContext> getContextMap() {
    return Map.from(_contextMap);
  }

  /// Checks if a given [TutorialID] exists in any of the internal maps.
  bool containsID(TutorialID? tutorialID) {
    return _keyMap.containsKey(tutorialID) ||
        _conditionMap.containsKey(tutorialID) ||
        _contextMap.containsKey(tutorialID);
  }

  /// Retrieves the value associated with a [TutorialID] from any of the internal maps.
  ///
  /// Returns null if the [TutorialID] is not found in any map.
  dynamic get(TutorialID tutorialID) {
    if (_keyMap.containsKey(tutorialID)) {
      return _keyMap[tutorialID] as GlobalKey;
    }
    if (_conditionMap.containsKey(tutorialID)) {
      return _conditionMap[tutorialID] as Future<bool> Function(Duration);
    }
    if (_contextMap.containsKey(tutorialID)) {
      return _contextMap[tutorialID] as BuildContext;
    }
    return null;
  }
}

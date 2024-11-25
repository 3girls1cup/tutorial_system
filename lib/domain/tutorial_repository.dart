import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_system/model/tutorial_overlay_config.dart';
import 'package:tutorial_system/tutorial_system.dart';

final tutorialRepositoryProvider = Provider<TutorialRepository>(
  (ref) => TutorialRepository(GlobalKey<NavigatorState>()),
);

/// A repository class for managing tutorial-related data and functions.
///
/// This class stores and provides access to various components needed for tutorials,
/// including widget keys, conditions, contexts, and tutorial containers.
class TutorialRepository {
  /// The global navigator key used for navigation in the app.
  final GlobalKey<NavigatorState> globalNavigatorKey;

  final Map<TutorialID, Stream<bool> Function()> _conditionStreamMap;

  /// A map of tutorial types to their corresponding [Tutorial] instances.
  final Map<Type, Tutorial> _tutorialContainers;

  /// A map of [TutorialID]s to their corresponding [GlobalKey]s.
  final Map<TutorialID, OverlayConfig> _configMap;

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
      Map<TutorialID, OverlayConfig>? keyMap,
      Map<TutorialID, Future<bool> Function(Duration)>? conditionMap,
      Map<TutorialID, Stream<bool> Function()>? conditionStreamMap,
      Map<TutorialID, BuildContext>? contextMap})
      : _tutorialContainers = _getTypedMap(tutorialContainers),
        _configMap = keyMap ?? {},
        _conditionMap = conditionMap ?? {},
        _conditionStreamMap = conditionStreamMap ?? {},
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
  void callRegistrationFunction(
      {required Type tutorialType,
      required dynamic caller,
      ConsumerState? state}) {
    Tutorial? tutorialContainer = _tutorialContainers[tutorialType];
    if (tutorialContainer != null) {
      tutorialContainer.registrationFunction(this, caller, state: state);
    }
  }

  /// Registers a [GlobalKey] for a specific [TutorialID].
  void registerConfig(TutorialID widgetID, OverlayConfig? key,
      {bool overwrite = false}) {
    if (key != null) {
      _configMap[widgetID] =
          overwrite ? key : _configMap[widgetID]?.copyWith(other: key) ?? key;
    }
  }

  /// Registers multiple [OverlayConfig]s at once.
  void registerAllConfigs(Map<TutorialID, OverlayConfig> keys,
      {bool overwrite = false}) {
    keys.forEach((key, value) {
      registerConfig(key, value, overwrite: overwrite);
    });
  }

  /// Removes a [GlobalKey] for a specific [TutorialID].
  void removeKey(TutorialID widgetID) {
    _configMap.remove(widgetID);
  }

  /// Retrieves a [GlobalKey] for a specific [TutorialID].
  OverlayConfig? getKey(TutorialID widgetID) {
    return _configMap[widgetID];
  }

  /// Registers a condition function for a specific [TutorialID].
  void registerFutureCondition(TutorialID conditionID,
      Future<bool> Function(Duration timeout) condition) {
    _conditionMap[conditionID] = condition;
  }

  void registerStreamCondition(
      TutorialID conditionID, Stream<bool> Function() condition) {
    _conditionStreamMap[conditionID] = condition;
  }

  void registerAllStreamConditions(
      Map<TutorialID, Stream<bool> Function()> conditions) {
    _conditionStreamMap.addAll(conditions);
  }

  void removeConditionStream(TutorialID conditionID) {
    _conditionStreamMap.remove(conditionID);
  }

  /// Registers multiple condition functions at once.
  void registerAllFutureConditions(
      Map<TutorialID, Future<bool> Function(Duration timeout)> conditions) {
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
    return Map.from(_configMap);
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
    return _configMap.containsKey(tutorialID) ||
        _conditionMap.containsKey(tutorialID) ||
        _contextMap.containsKey(tutorialID);
  }

  /// Retrieves the value associated with a [TutorialID] from any of the internal maps.
  ///
  /// Returns null if the [TutorialID] is not found in any map.
  TutorialRegistration get(TutorialID tutorialID) {
    OverlayConfig? key;
    Future<bool> Function(Duration)? condition;
    BuildContext? context;
    Stream<bool> Function()? streamCondition;
    if (_configMap.containsKey(tutorialID)) {
      key = _configMap[tutorialID] as OverlayConfig;
    }
    if (_conditionMap.containsKey(tutorialID)) {
      condition = _conditionMap[tutorialID] as Future<bool> Function(Duration);
    }
    if (_contextMap.containsKey(tutorialID)) {
      context = _contextMap[tutorialID] as BuildContext;
    }

    if (_conditionStreamMap.containsKey(tutorialID)) {
      streamCondition =
          _conditionStreamMap[tutorialID] as Stream<bool> Function();
    }
    return TutorialRegistration(
        overlayConfig: key,
        condition: condition,
        context: context,
        streamCondition: streamCondition);
  }
}

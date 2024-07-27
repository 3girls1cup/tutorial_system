import 'package:flutter/material.dart';
import 'package:tutorial_system/tutorial_system.dart';

class TutorialKeyRepository {
  final GlobalKey<NavigatorState> globalNavigatorKey;

  final Map<Type, TutorialContainer> _tutorialContainers;

  final Map<TutorialID, GlobalKey> _keyMap;
  final Map<TutorialID, Future<bool> Function(Duration)> _conditionMap;
  final Map<TutorialID, BuildContext> _contextMap;

  TutorialKeyRepository(this.globalNavigatorKey,
      {List<TutorialContainer>? tutorialContainers,
        Map<TutorialID, GlobalKey>? keyMap,
        Map<TutorialID, Future<bool> Function(Duration)>? conditionMap,
        Map<TutorialID, BuildContext>? contextMap})
      : _tutorialContainers = _getTypedMap(tutorialContainers),
        _keyMap = keyMap ?? {},
        _conditionMap = conditionMap ?? {},
        _contextMap = contextMap ?? {};

  static Map<Type, TutorialContainer> _getTypedMap(List<TutorialContainer>? containers) {
    Map<Type, TutorialContainer> result = {};
    for (TutorialContainer tutorialContainer in containers ?? []) {
      result[tutorialContainer.runtimeType] = tutorialContainer;
    }
    return result;
  }

  void callRegistrationFunction({required Type tutorialType, required dynamic caller, State? state}) {
    TutorialContainer? tutorialContainer = _tutorialContainers[tutorialType];
    if (tutorialContainer != null) {
      tutorialContainer.registrationFunction(this, caller, state: state);
    }
  }

  void registerKey(TutorialID widgetID, GlobalKey? key) {
    if (key != null) {
      _keyMap[widgetID] = key;
    }
  }

  void registerKeys(Map<TutorialID, GlobalKey> keys) {
    _keyMap.addAll(keys);
  }

  void removeKey(TutorialID widgetID) {
    _keyMap.remove(widgetID);
  }

  GlobalKey? getKey(TutorialID widgetID) {
    return _keyMap[widgetID];
  }

  void registerCondition(TutorialID conditionID, Future<bool> Function(Duration timeout) condition) {
    _conditionMap[conditionID] = condition;
  }

  void registerConditions(Map<TutorialID, Future<bool> Function(Duration timeout)> conditions) {
    _conditionMap.addAll(conditions);
  }

  void removeCondition(TutorialID conditionID) {
    _conditionMap.remove(conditionID);
  }

  Future<bool> Function(Duration)? getCondition(TutorialID conditionID) {
    return _conditionMap[conditionID];
  }

  void registerContext(TutorialID contextID, BuildContext? buildContext) {
    if (buildContext != null) {
      _contextMap[contextID] = buildContext;
    }
  }

  void registerContexts(Map<TutorialID, BuildContext> contexts) {
    _contextMap.addAll(contexts);
  }

  void removeContext(TutorialID contextID) {
    _contextMap.remove(contextID);
  }

  BuildContext? getContext(TutorialID contextID) {
    return _contextMap[contextID];
  }

  Map<TutorialID, GlobalKey> getKeyMap() {
    return Map.from(_keyMap);
  }

  Map<TutorialID, bool Function()> getConditionMap() {
    return Map.from(_conditionMap);
  }

  Map<TutorialID, BuildContext> getContextMap() {
    return Map.from(_contextMap);
  }

  bool containsID(TutorialID? tutorialID) {
    return _keyMap.containsKey(tutorialID) ||
        _conditionMap.containsKey(tutorialID) ||
        _contextMap.containsKey(tutorialID);
  }

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

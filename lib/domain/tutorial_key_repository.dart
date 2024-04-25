import 'package:flutter/material.dart';
import 'package:tutorial_system/tutorial_system.dart';

class TutorialKeyRepository {
  final GlobalKey<NavigatorState> globalNavigatorKey;

  final Map<TutorialID, GlobalKey> _keyMap = {};
  final Map<TutorialID, bool Function()> _conditionMap = {};
  final Map<TutorialID, BuildContext> _contextMap = {};

  TutorialKeyRepository(this.globalNavigatorKey);

  void registerKey(TutorialID widgetID, GlobalKey key) {
    _keyMap[widgetID] = key;
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

  void registerCondition(TutorialID conditionID, bool Function() condition) {
    _conditionMap[conditionID] = condition;
  }

  void removeCondition(TutorialID conditionID) {
    _conditionMap.remove(conditionID);
  }

  bool Function()? getCondition(TutorialID conditionID) {
    return _conditionMap[conditionID];
  }

  void registerContext(TutorialID contextID, BuildContext buildContext) {
    _contextMap[contextID] = buildContext;
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
    if(_keyMap.containsKey(tutorialID)) {
      return _keyMap[tutorialID] as GlobalKey;
    }
    if(_conditionMap.containsKey(tutorialID)) {
      return _conditionMap[tutorialID] as bool Function();
    }
    if(_contextMap.containsKey(tutorialID)) {
      return _contextMap[tutorialID] as BuildContext;
    }
    return null;
  }
}

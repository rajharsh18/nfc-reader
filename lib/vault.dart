import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class Vault extends ChangeNotifier {
  Vault(this._prefs) {
    _load();
  }

  static const _storageKey = 'gatekey.vault';

  final SharedPreferences _prefs;
  List<SavedCard> _cards = [];
  List<Gate> _gates = [];
  List<AccessEvent> _events = [];

  List<SavedCard> get cards => List.unmodifiable(_cards);
  List<Gate> get gates => List.unmodifiable(_gates);
  List<AccessEvent> get events => List.unmodifiable(_events);

  SavedCard? cardById(String id) {
    for (final card in _cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  SavedCard? cardByUid(String uid) {
    for (final card in _cards) {
      if (card.uid == uid) return card;
    }
    return null;
  }

  Gate? gateById(String id) {
    for (final gate in _gates) {
      if (gate.id == id) return gate;
    }
    return null;
  }

  void saveCard(SavedCard card) {
    final index = _cards.indexWhere((item) => item.id == card.id);
    if (index >= 0) {
      _cards[index] = card;
    } else {
      _cards = [card, ..._cards];
    }
    _commit();
  }

  void deleteCard(String id) {
    _cards = [for (final card in _cards) if (card.id != id) card];
    _commit();
  }

  void saveGate(Gate gate) {
    final index = _gates.indexWhere((item) => item.id == gate.id);
    if (index >= 0) {
      _gates[index] = gate;
    } else {
      _gates = [..._gates, gate];
    }
    _commit();
  }

  void deleteGate(String id) {
    _gates = [for (final gate in _gates) if (gate.id != id) gate];
    _cards = [
      for (final card in _cards)
        card.copyWith(
          gateIds: [for (final gateId in card.gateIds) if (gateId != id) gateId],
        ),
    ];
    _commit();
  }

  void addEvent(AccessEvent event) {
    _events = [event, ..._events];
    if (_events.length > 80) {
      _events = _events.sublist(0, 80);
    }
    _commit();
  }

  void clearEvents() {
    _events = [];
    _commit();
  }

  void _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      _gates = [...defaultGates];
      _persist();
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cards = [
        for (final item in json['cards'] as List<dynamic>? ?? const [])
          SavedCard.fromJson(item as Map<String, dynamic>),
      ];
      _gates = [
        for (final item in json['gates'] as List<dynamic>? ?? const [])
          Gate.fromJson(item as Map<String, dynamic>),
      ];
      _events = [
        for (final item in json['events'] as List<dynamic>? ?? const [])
          AccessEvent.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      _cards = [];
      _gates = [...defaultGates];
      _events = [];
      _persist();
    }
  }

  void _commit() {
    _persist();
    notifyListeners();
  }

  void _persist() {
    _prefs.setString(
      _storageKey,
      jsonEncode({
        'cards': [for (final card in _cards) card.toJson()],
        'gates': [for (final gate in _gates) gate.toJson()],
        'events': [for (final event in _events) event.toJson()],
      }),
    );
  }
}

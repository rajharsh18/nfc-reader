import 'dart:async';

import 'package:flutter/material.dart';

import '../nfc_service.dart';
import '../theme.dart';
import '../widgets.dart';

class PresentPage extends StatefulWidget {
  const PresentPage({required this.cardId, super.key});

  final String cardId;

  @override
  State<PresentPage> createState() => _PresentPageState();
}

class _PresentPageState extends State<PresentPage> {
  StreamSubscription<CardReaderEvent>? _readerEvents;
  Timer? _readyAgain;
  var _starting = true;
  var _touching = false;
  var _seen = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _readerEvents = CardEmulator.readerEvents().listen(
      _onReader,
      onError: (_) {},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_begin());
    });
  }

  @override
  void dispose() {
    _readyAgain?.cancel();
    unawaited(_readerEvents?.cancel());
    unawaited(CardEmulator.stop());
    super.dispose();
  }

  void _onReader(CardReaderEvent event) {
    if (!mounted || _error != null) return;
    switch (event) {
      case CardReaderEvent.selected:
        final holding = _readyAgain != null;
        _readyAgain?.cancel();
        _readyAgain = null;
        setState(() {
          _touching = true;
          if (holding) _seen = false;
        });
      case CardReaderEvent.read:
        _readyAgain?.cancel();
        _readyAgain = null;
        setState(() {
          _touching = true;
          _seen = true;
        });
      case CardReaderEvent.left:
        if (!_seen) {
          setState(() => _touching = false);
          return;
        }
        _readyAgain?.cancel();
        _readyAgain = Timer(const Duration(milliseconds: 1200), () {
          _readyAgain = null;
          if (!mounted) return;
          setState(() {
            _seen = false;
            _touching = false;
          });
        });
    }
  }

  String get _caption {
    if (_starting) return 'Starting';
    if (_error != null) return 'Not presenting';
    if (_seen) return 'Reader saw this card';
    if (_touching) return 'Reader is here';
    return 'Ready at the gate';
  }

  Future<void> _begin() async {
    final vault = VaultScope.of(context);
    final card = vault.cardById(widget.cardId);
    if (card == null) return;
    try {
      await CardEmulator.start(card.uid);
      if (!mounted) return;
      setState(() => _starting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = error is StateError
            ? error.message
            : 'Could not present this card.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = VaultScope.of(context);
    final card = vault.cardById(widget.cardId);
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Present card')),
        body: const Center(child: Text('This card was removed.')),
      );
    }
    final gates = [
      for (final gate in vault.gates)
        if (card.gateIds.contains(gate.id)) gate.name,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Present card')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          CredentialFace(
            name: card.name,
            uid: card.uid,
            caption: _caption,
            highlight: _seen && _error == null,
          ),
          const SizedBox(height: 22),
          Text(
            _error ?? 'Hold the back of this phone against the reader. This card turns blue when that reader speaks to the phone and reads the saved number.',
            style: TextStyle(
              color: _error == null ? mist : coral,
              height: 1.4,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            gates.isEmpty
                ? 'This card cannot open any gate yet.'
                : 'Allowed through ${gates.join(', ')}.',
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'A door that checks the plastic card’s chip id still needs that card. Open the gate in this app and tap the card on this phone.',
            style: TextStyle(color: mist, height: 1.4),
          ),
        ],
      ),
    );
  }
}

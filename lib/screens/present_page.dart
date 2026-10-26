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
  var _starting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_begin());
    });
  }

  @override
  void dispose() {
    unawaited(CardEmulator.stop());
    super.dispose();
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
            caption: _starting
                ? 'Starting'
                : _error == null
                ? 'Ready at the gate'
                : 'Not presenting',
          ),
          const SizedBox(height: 22),
          Text(
            _error ??
            'Hold the back of this phone against a GateKey gate. The gate reads this card’s number and opens when the card is allowed.',
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
            'A reader that only checks a plastic card’s chip id will not accept the phone. Use the physical card for those readers.',
            style: TextStyle(color: mist, height: 1.4),
          ),
        ],
      ),
    );
  }
}

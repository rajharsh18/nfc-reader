import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../nfc_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'present_page.dart';

class CardPage extends StatefulWidget {
  const CardPage({required this.cardId, super.key});

  final String cardId;

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  var _canPresent = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPresent());
  }

  Future<void> _loadPresent() async {
    final supported = await CardEmulator.supported();
    if (!mounted) return;
    setState(() => _canPresent = supported);
  }

  @override
  Widget build(BuildContext context) {
    final vault = VaultScope.of(context);
    final card = vault.cardById(widget.cardId);
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Card')),
        body: const Center(child: Text('This card was removed.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card'),
        actions: [
          IconButton(
            tooltip: 'Rename',
            onPressed: () => _rename(card),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _delete(card),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          CredentialFace(
            name: card.name,
            uid: card.uid,
            caption: card.technologies.isEmpty
                ? 'Saved ${formatWhen(card.savedAt)}'
                : '${card.technologies} · ${formatWhen(card.savedAt)}',
          ),
          const SizedBox(height: 22),
          const Text(
            'Gates this card can open',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final gate in vault.gates)
                FilterChip(
                  label: Text(gate.name),
                  selected: card.gateIds.contains(gate.id),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: card.gateIds.contains(gate.id) ? onBlue : foam,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: blue,
                  backgroundColor: paper,
                  side: BorderSide(
                    color: card.gateIds.contains(gate.id) ? blue : line,
                  ),
                  onSelected: (selected) {
                    final next = [...card.gateIds];
                    if (selected) {
                      next.add(gate.id);
                    } else {
                      next.remove(gate.id);
                    }
                    vault.saveCard(card.copyWith(gateIds: next));
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'At a gate, open that gate in this app and tap the physical card. The phone checks the card number against the gates selected here.',
            style: TextStyle(color: mist, height: 1.4),
          ),
          if (_canPresent ||
              defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canPresent
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PresentPage(cardId: card.id),
                        ),
                      );
                    }
                  : null,
              child: Text(
                _canPresent
                    ? 'Hold this phone to a gate'
                    : 'This phone cannot present a card',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Holding the phone to a GateKey gate sends this saved number. A reader that only checks a plastic card’s chip id still needs that card.',
              style: TextStyle(color: mist, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _rename(SavedCard card) async {
    final name = await promptForText(
      context,
      title: 'Rename card',
      confirm: 'Save',
      initial: card.name,
    );
    if (!mounted || name == null) return;
    VaultScope.of(context).saveCard(card.copyWith(name: name));
  }

  Future<void> _delete(SavedCard card) async {
    final remove = await confirmAction(
      context,
      title: 'Delete ${card.name}?',
      message: 'The card can be saved again by reading it.',
      confirm: 'Delete',
    );
    if (!mounted || !remove) return;
    VaultScope.of(context).deleteCard(card.id);
    Navigator.pop(context);
  }
}

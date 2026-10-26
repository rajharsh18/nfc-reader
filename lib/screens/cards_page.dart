import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../nfc_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'card_page.dart';
import 'save_card_page.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> with WidgetsBindingObserver {
  NfcAvailability? _nfc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshNfc());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshNfc());
  }

  Future<void> _refreshNfc() async {
    final availability = await checkNfc();
    if (!mounted) return;
    setState(() => _nfc = availability);
  }

  @override
  Widget build(BuildContext context) {
    final vault = VaultScope.of(context);
    final cards = vault.cards;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: PageHeader(
              title: 'Saved cards',
              subtitle: 'Read a card once, then use it when you reach a gate.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: _statusLabel(_nfc),
                color: _statusColor(_nfc),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SaveCardPage()),
                );
              },
              child: const Text('Save a card'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: cards.isEmpty
                ? const _EmptyCards()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return CredentialFace(
                        name: card.name,
                        uid: card.uid,
                        caption: allowedGateLabel(vault.gates, card),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => CardPage(cardId: card.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, color: blue, size: 48),
          SizedBox(height: 14),
          Text(
            'No cards saved',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Save the card you carry, choose which gates it opens, then check it on the Gates tab.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mist, height: 1.4),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(NfcAvailability? availability) {
  return switch (availability) {
    NfcAvailability.enabled => 'NFC ready',
    NfcAvailability.disabled => 'NFC is off',
    NfcAvailability.unsupported => 'No NFC on this phone',
    null => 'Checking NFC',
  };
}

Color _statusColor(NfcAvailability? availability) {
  return switch (availability) {
    NfcAvailability.enabled => blue,
    NfcAvailability.disabled => sky,
    NfcAvailability.unsupported => coral,
    null => mist,
  };
}

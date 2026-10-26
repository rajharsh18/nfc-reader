import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../nfc_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'card_page.dart';

class SaveCardPage extends StatefulWidget {
  const SaveCardPage({super.key});

  @override
  State<SaveCardPage> createState() => _SaveCardPageState();
}

class _SaveCardPageState extends State<SaveCardPage> {
  final _name = TextEditingController();
  final _nfc = NfcScan();
  final _gates = <String>{};
  ScannedIdentity? _identity;
  var _scanning = false;
  var _prepared = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prepared) return;
    _prepared = true;
    final vault = VaultScope.of(context);
    _name.text = 'Card ${vault.cards.length + 1}';
    if (vault.gateById('main') != null) {
      _gates.add('main');
    } else if (vault.gates.isNotEmpty) {
      _gates.add(vault.gates.first.id);
    }
  }

  @override
  void dispose() {
    unawaited(_nfc.cancel());
    _name.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final identity = await _nfc.once(
        'Hold the card near the top of the iPhone.',
      );
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _identity = identity;
        if (identity == null) {
          _error = null;
        } else if (!identity.hasNumber) {
          _error = 'This tag has no card number.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = nfcErrorMessage(error);
      });
    }
  }

  Future<void> _typeNumber() async {
    final raw = await promptForText(
      context,
      title: 'Card number',
      confirm: 'Use number',
      hint: '04 AA BB CC DD',
      maxLength: 40,
      capitalization: TextCapitalization.characters,
    );
    if (!mounted || raw == null) return;
    final uid = normalizeUid(raw);
    if (uid == null) {
      setState(() => _error = 'Enter an even-length hex number, at least 4 digits.');
      return;
    }
    setState(() {
      _identity = ScannedIdentity(
        hardwareUid: uid,
        credentialUid: null,
        technologies: const ['Typed'],
      );
      _error = null;
    });
  }

  void _save() {
    final vault = VaultScope.of(context);
    final identity = _identity;
    final uid = identity?.enrollUid;
    if (uid == null) {
      setState(() => _error = 'Read a card before saving it.');
      return;
    }
    final existing = vault.cardByUid(uid);
    if (existing != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => CardPage(cardId: existing.id)),
      );
      return;
    }
    final name = _name.text.trim().isEmpty ? 'Untitled card' : _name.text.trim();
    final card = SavedCard(
      id: newId(),
      name: name,
      uid: uid,
      gateIds: _gates.toList(),
      technologies: identity!.technologies.join(' · '),
      savedAt: DateTime.now(),
    );
    vault.saveCard(card);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vault = VaultScope.of(context);
    final uid = _identity?.enrollUid;
    final existing = uid == null ? null : vault.cardByUid(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Save a card')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Give the card a name, choose the gates it may open, then hold it against the phone.',
            style: TextStyle(color: mist, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 22),
          const Text(
            'Allowed gates',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (vault.gates.isEmpty)
            const Text(
              'Add a gate first, then come back to save a card.',
              style: TextStyle(color: mist),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final gate in vault.gates)
                  FilterChip(
                    label: Text(gate.name),
                    selected: _gates.contains(gate.id),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: _gates.contains(gate.id) ? limeInk : foam,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: lime,
                    backgroundColor: paper,
                    side: BorderSide(
                      color: _gates.contains(gate.id) ? lime : line,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _gates.add(gate.id);
                        } else {
                          _gates.remove(gate.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          const SizedBox(height: 22),
          if (uid != null)
            ListenableBuilder(
              listenable: _name,
              builder: (context, _) {
                final typed = _name.text.trim();
                return CredentialFace(
                  name: typed.isEmpty ? 'Untitled card' : typed,
                  uid: uid,
                  caption: _identity!.technologies.isEmpty
                      ? 'NFC card'
                      : _identity!.technologies.join(' · '),
                );
              },
            )
          else
            _ScanPanel(scanning: _scanning),
          if (existing != null) ...[
            const SizedBox(height: 12),
            Text(
              'Already saved as ${existing.name}. Saving opens that card.',
              style: const TextStyle(color: brass, height: 1.35),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: coral, height: 1.35)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _scanning ? null : (uid == null ? _read : _save),
            child: Text(
              _scanning
                  ? 'Hold the card still'
                  : uid == null
                  ? 'Read card'
                  : existing == null
                  ? 'Save card'
                  : 'Open saved card',
            ),
          ),
          if (uid != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _scanning ? null : _read,
              child: const Text('Read again'),
            ),
          ],
          TextButton(
            onPressed: _scanning ? null : _typeNumber,
            child: const Text('Type a card number'),
          ),
        ],
      ),
    );
  }
}

class _ScanPanel extends StatelessWidget {
  const _ScanPanel({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: line),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            scanning ? Icons.wifi_tethering : Icons.contactless,
            color: lime,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            scanning
                ? 'Listening for a card'
                : 'Hold the card flat against the back of the phone',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.35),
          ),
        ],
      ),
    );
  }
}

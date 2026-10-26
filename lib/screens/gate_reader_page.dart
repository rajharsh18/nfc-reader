import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../nfc_service.dart';
import '../theme.dart';
import '../widgets.dart';

class GateReaderPage extends StatefulWidget {
  const GateReaderPage({required this.gateId, super.key});

  final String gateId;

  @override
  State<GateReaderPage> createState() => _GateReaderPageState();
}

class _GateReaderPageState extends State<GateReaderPage> {
  final _nfc = NfcScan();
  AccessDecision? _decision;
  String? _error;
  var _scanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_scan());
    });
  }

  @override
  void dispose() {
    unawaited(_nfc.cancel());
    super.dispose();
  }

  Future<void> _scan() async {
    final gate = VaultScope.of(context).gateById(widget.gateId);
    if (gate == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _scanning = true;
      _decision = null;
      _error = null;
    });
    try {
      final identity = await _nfc.once('Hold the card near the top of the iPhone.');
      if (!mounted) return;
      if (identity == null) {
        setState(() => _scanning = false);
        return;
      }
      if (!identity.hasNumber) {
        setState(() {
          _scanning = false;
          _error = 'This tag has no card number.';
        });
        return;
      }
      final vault = VaultScope.of(context);
      final currentGate = vault.gateById(widget.gateId);
      if (currentGate == null) return;
      final decision = decideAccess(
        gate: currentGate,
        cards: vault.cards,
        hardwareUid: identity.hardwareUid,
        credentialUid: identity.credentialUid,
      );
      vault.addEvent(
        AccessEvent(
          id: newId(),
          at: DateTime.now(),
          gateId: currentGate.id,
          gateName: currentGate.name,
          cardName: decision.card?.name ?? 'Unknown card',
          uid: decision.uid,
          granted: decision.granted,
          message: decision.message,
        ),
      );
      if (decision.granted) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.heavyImpact();
      }
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _decision = decision;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = nfcErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gate = VaultScope.of(context).gateById(widget.gateId);
    final decision = _decision;

    return Scaffold(
      appBar: AppBar(title: Text(gate?.name ?? 'Gate')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            gate?.detail ?? '',
            style: const TextStyle(color: mist, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a saved card, or hold a phone that is presenting one.',
            style: TextStyle(color: mist, height: 1.4),
          ),
          const SizedBox(height: 22),
          if (decision != null)
            _Result(decision: decision)
          else
            _Wait(scanning: _scanning, error: _error),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _scanning ? null : _scan,
            child: Text(_scanning ? 'Hold the card still' : 'Check a card'),
          ),
        ],
      ),
    );
  }
}

class _Wait extends StatelessWidget {
  const _Wait({required this.scanning, required this.error});

  final bool scanning;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: line),
      ),
      child: Column(
        children: [
          Icon(
            scanning ? Icons.wifi_tethering : Icons.sensor_door_outlined,
            color: lime,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            scanning ? 'Listening for a card' : 'Ready for a card',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: coral, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.decision});

  final AccessDecision decision;

  @override
  Widget build(BuildContext context) {
    final granted = decision.granted;
    final background = granted ? lime : coral;
    final foreground = granted ? limeInk : const Color(0xFF2D0906);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            granted ? 'GRANTED' : 'DENIED',
            style: TextStyle(
              color: foreground,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            decision.message,
            style: TextStyle(color: foreground, fontSize: 16, height: 1.35),
          ),
          if (decision.uid.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              formatUid(decision.uid),
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

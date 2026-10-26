import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import 'credential.dart';

class ScannedIdentity {
  const ScannedIdentity({
    required this.hardwareUid,
    required this.credentialUid,
    required this.technologies,
  });

  final String? hardwareUid;
  final String? credentialUid;
  final List<String> technologies;

  bool get hasNumber => hardwareUid != null || credentialUid != null;

  /// Number stored for a newly enrolled card. A plastic card keeps its chip
  /// id. A phone that is presenting a saved card has no stable chip id, so
  /// the credential inside the tag is used instead.
  String? get enrollUid => hardwareUid ?? credentialUid;
}

Future<NfcAvailability> checkNfc() async {
  try {
    return await NfcManager.instance.checkAvailability();
  } catch (_) {
    return NfcAvailability.unsupported;
  }
}

String nfcErrorMessage(Object error) {
  final text = error.toString().toLowerCase();
  if (error is UnsupportedError || text.contains('not_supported')) {
    return 'This phone has no NFC reader.';
  }
  if (text.contains('disabled') || text.contains('not_enabled')) {
    return 'Turn on NFC in system settings, then try again.';
  }
  return 'Could not read a card. Hold it flat against the phone and try again.';
}

class NfcScan {
  Completer<ScannedIdentity?>? _pending;

  Future<ScannedIdentity?> once(String alert) async {
    await cancel();
    final completer = Completer<ScannedIdentity?>();
    _pending = completer;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        alertMessageIos: alert,
        invalidateAfterFirstReadIos: true,
        onDiscovered: (tag) async {
          if (completer.isCompleted) return;
          try {
            final identity = await readIdentity(tag);
            if (!completer.isCompleted) completer.complete(identity);
            await NfcManager.instance.stopSession(
              alertMessageIos: identity.hasNumber ? 'Card read.' : null,
              errorMessageIos: identity.hasNumber
                  ? null
                  : 'This card has no number.',
            );
          } catch (_) {
            if (!completer.isCompleted) {
              completer.completeError(StateError('Could not read this card.'));
            }
            await _stop(error: 'Could not read this card.');
          }
        },
        onSessionErrorIos: (error) {
          if (!completer.isCompleted) completer.complete(null);
        },
      );
    } catch (error) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    return completer.future;
  }

  Future<void> cancel() async {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    await _stop();
  }

  Future<void> _stop({String? error}) async {
    try {
      await NfcManager.instance.stopSession(errorMessageIos: error);
    } catch (_) {}
  }
}

Future<ScannedIdentity> readIdentity(NfcTag tag) async {
  return ScannedIdentity(
    hardwareUid: _hardwareUid(tag),
    credentialUid: await _credentialUid(tag),
    technologies: _technologies(tag),
  );
}

String? _hardwareUid(NfcTag tag) {
  Uint8List? bytes;
  if (defaultTargetPlatform == TargetPlatform.android) {
    final android = NfcTagAndroid.from(tag);
    if (android != null && android.id.isNotEmpty) bytes = android.id;
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    final mifare = MiFareIos.from(tag);
    final iso15693 = Iso15693Ios.from(tag);
    final iso7816 = Iso7816Ios.from(tag);
    final felica = FeliCaIos.from(tag);
    if (mifare != null && mifare.identifier.isNotEmpty) {
      bytes = mifare.identifier;
    } else if (iso15693 != null && iso15693.identifier.isNotEmpty) {
      bytes = iso15693.identifier;
    } else if (iso7816 != null && iso7816.identifier.isNotEmpty) {
      bytes = iso7816.identifier;
    } else if (felica != null && felica.currentIDm.isNotEmpty) {
      bytes = felica.currentIDm;
    }
  }
  if (bytes == null || bytes.isEmpty) return null;
  return _hex(bytes);
}

Future<String?> _credentialUid(NfcTag tag) async {
  try {
    final records = await _records(tag);
    for (final record in records) {
      final uid = uidFromNdefRecord(record);
      if (uid != null) return uid;
    }
  } catch (_) {}
  return null;
}

Future<List<NdefRecord>> _records(NfcTag tag) async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final ndef = NdefAndroid.from(tag);
    final message = ndef?.cachedNdefMessage ?? await ndef?.getNdefMessage();
    return message?.records ?? const [];
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final ndef = NdefIos.from(tag);
    final message = ndef?.cachedNdefMessage ?? await ndef?.readNdef();
    return message?.records ?? const [];
  }
  return const [];
}

List<String> _technologies(NfcTag tag) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return [
      for (final tech in NfcTagAndroid.from(tag)?.techList ?? const <String>[])
        _shortTech(tech),
    ];
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return [
      if (MiFareIos.from(tag) != null) 'MiFare',
      if (Iso15693Ios.from(tag) != null) 'ISO15693',
      if (Iso7816Ios.from(tag) != null) 'ISO7816',
      if (FeliCaIos.from(tag) != null) 'FeliCa',
      if (NdefIos.from(tag) != null) 'NDEF',
    ];
  }
  return const [];
}

String _shortTech(String value) {
  final dot = value.lastIndexOf('.');
  return dot == -1 ? value : value.substring(dot + 1);
}

String _hex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString().toUpperCase();
}

class CardEmulator {
  static const _channel = MethodChannel('com.gatekey.nfc_reader/hce');

  static Future<bool> supported() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('supported') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> start(String uid) async {
    final ok = await _channel.invokeMethod<bool>('start', {
      'payload': credentialText(uid),
    });
    if (ok != true) {
      throw StateError('This phone cannot present a card.');
    }
  }

  static Future<void> stop() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_reader/credential.dart';
import 'package:nfc_reader/models.dart';
import 'package:nfc_reader/nfc_service.dart';
import 'package:nfc_reader/vault.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const mainGate = Gate(
    id: 'main',
    name: 'Main gate',
    detail: 'Front entrance',
  );
  const server = Gate(id: 'server', name: 'Server room', detail: 'Restricted');

  SavedCard card({
    String id = 'card-1',
    String uid = '04AABBCCDD',
    List<String> gateIds = const ['main'],
    String name = 'Front desk',
  }) {
    return SavedCard(
      id: id,
      name: name,
      uid: uid,
      gateIds: gateIds,
      technologies: 'NfcA',
      savedAt: DateTime.utc(2026, 10, 26),
    );
  }

  test('normalizes card numbers', () {
    expect(normalizeUid('04 aa:bb-cc dd'), '04AABBCCDD');
    expect(normalizeUid('abc'), isNull);
    expect(normalizeUid('ABCD'), 'ABCD');
    expect(formatUid('04AABB'), '04 AA BB');
  });

  test('grants a saved card only at its gates', () {
    final saved = card();
    final granted = decideAccess(
      gate: mainGate,
      cards: [saved],
      hardwareUid: saved.uid,
      credentialUid: null,
    );
    final denied = decideAccess(
      gate: server,
      cards: [saved],
      hardwareUid: saved.uid,
      credentialUid: null,
    );
    final unknown = decideAccess(
      gate: mainGate,
      cards: [saved],
      hardwareUid: '11223344',
      credentialUid: null,
    );

    expect(granted.granted, isTrue);
    expect(granted.card?.name, 'Front desk');
    expect(denied.granted, isFalse);
    expect(denied.message, contains('Server room'));
    expect(unknown.granted, isFalse);
  });

  test('a presented phone is matched by its credential', () {
    final saved = card();
    final decision = decideAccess(
      gate: mainGate,
      cards: [saved],
      hardwareUid: 'DEADBEEF',
      credentialUid: saved.uid,
    );
    expect(decision.granted, isTrue);
    expect(decision.card?.id, saved.id);
  });

  test('disagrees when the chip and credential are different cards', () {
    final first = card();
    final second = card(id: 'card-2', uid: '11223344', name: 'Workshop');
    final decision = decideAccess(
      gate: mainGate,
      cards: [first, second],
      hardwareUid: first.uid,
      credentialUid: second.uid,
    );
    expect(decision.granted, isFalse);
  });

  test('a failed reader session stays visible', () {
    expect(
      nfcSessionFailure(
        const NfcReaderSessionErrorIos(
          code: NfcReaderErrorCodeIos
              .readerSessionInvalidationErrorSessionTimeout,
          message: 'timeout',
        ),
      ),
      contains('timed out'),
    );
    expect(
      nfcSessionFailure(
        const NfcReaderSessionErrorIos(
          code:
              NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled,
          message: 'cancel',
        ),
      ),
      isNull,
    );
    expect(
      nfcErrorMessage(StateError('NFC is busy. Try again in a moment.')),
      'NFC is busy. Try again in a moment.',
    );
  });

  test('reads a GateKey text record', () {
    const uid = '04AABBCCDD';
    final payload = Uint8List.fromList([
      0x02,
      0x65,
      0x6E,
      ...utf8.encode(credentialText(uid)),
    ]);
    final record = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]),
      identifier: Uint8List(0),
      payload: payload,
    );
    expect(uidFromNdefRecord(record), uid);
  });

  test('keeps cards after a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = Vault(await SharedPreferences.getInstance());
    first.saveCard(card());
    final second = Vault(await SharedPreferences.getInstance());
    expect(second.cards.single.name, 'Front desk');
    expect(second.gates.map((gate) => gate.id), contains('server'));
  });
}

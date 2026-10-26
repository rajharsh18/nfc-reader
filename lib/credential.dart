import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef_record/ndef_record.dart';

import 'models.dart';

const credentialPrefix = 'GK1:';

String credentialText(String uid) => '$credentialPrefix$uid';

String? uidFromCredentialText(String text) {
  final match = RegExp(
    'GK1:([0-9A-Fa-f]+)',
  ).firstMatch(text.replaceAll(RegExp(r'\s'), ''));
  final raw = match?.group(1);
  if (raw == null) return null;
  return normalizeUid(raw);
}

String? uidFromNdefRecord(NdefRecord record) {
  final text = _recordText(record);
  if (text == null) return null;
  return uidFromCredentialText(text);
}

String? _recordText(NdefRecord record) {
  final type = utf8.decode(record.type, allowMalformed: true);
  if (record.typeNameFormat == TypeNameFormat.wellKnown && type == 'T') {
    return _decodeTextPayload(record.payload);
  }
  if (record.typeNameFormat == TypeNameFormat.media &&
      type.toLowerCase().startsWith('text/')) {
    return utf8.decode(record.payload, allowMalformed: true);
  }
  return null;
}

String? _decodeTextPayload(Uint8List payload) {
  if (payload.isEmpty) return null;
  final status = payload[0];
  final languageLength = status & 0x3F;
  final start = 1 + languageLength;
  if (start > payload.length) return null;
  final data = payload.sublist(start);
  if ((status & 0x80) == 0) {
    return utf8.decode(data, allowMalformed: true);
  }
  if (data.length.isOdd) return null;
  final units = <int>[];
  for (var index = 0; index + 1 < data.length; index += 2) {
    units.add((data[index] << 8) | data[index + 1]);
  }
  return String.fromCharCodes(units);
}

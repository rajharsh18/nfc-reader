class SavedCard {
  const SavedCard({
    required this.id,
    required this.name,
    required this.uid,
    required this.gateIds,
    required this.technologies,
    required this.savedAt,
  });

  final String id;
  final String name;
  final String uid;
  final List<String> gateIds;
  final String technologies;
  final DateTime savedAt;

  SavedCard copyWith({
    String? name,
    List<String>? gateIds,
    String? technologies,
  }) {
    return SavedCard(
      id: id,
      name: name ?? this.name,
      uid: uid,
      gateIds: gateIds ?? this.gateIds,
      technologies: technologies ?? this.technologies,
      savedAt: savedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'uid': uid,
    'gateIds': gateIds,
    'technologies': technologies,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] as String,
      name: json['name'] as String,
      uid: json['uid'] as String,
      gateIds: [
        for (final gateId in json['gateIds'] as List<dynamic>? ?? const [])
          gateId.toString(),
      ],
      technologies: json['technologies'] as String? ?? '',
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

class Gate {
  const Gate({required this.id, required this.name, required this.detail});

  final String id;
  final String name;
  final String detail;

  Gate copyWith({String? name, String? detail}) {
    return Gate(
      id: id,
      name: name ?? this.name,
      detail: detail ?? this.detail,
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'detail': detail};

  factory Gate.fromJson(Map<String, dynamic> json) {
    return Gate(
      id: json['id'] as String,
      name: json['name'] as String,
      detail: json['detail'] as String? ?? '',
    );
  }
}

class AccessEvent {
  const AccessEvent({
    required this.id,
    required this.at,
    required this.gateId,
    required this.gateName,
    required this.cardName,
    required this.uid,
    required this.granted,
    required this.message,
  });

  final String id;
  final DateTime at;
  final String gateId;
  final String gateName;
  final String cardName;
  final String uid;
  final bool granted;
  final String message;

  Map<String, Object?> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'gateId': gateId,
    'gateName': gateName,
    'cardName': cardName,
    'uid': uid,
    'granted': granted,
    'message': message,
  };

  factory AccessEvent.fromJson(Map<String, dynamic> json) {
    return AccessEvent(
      id: json['id'] as String,
      at: DateTime.parse(json['at'] as String),
      gateId: json['gateId'] as String,
      gateName: json['gateName'] as String,
      cardName: json['cardName'] as String? ?? 'Unknown card',
      uid: json['uid'] as String? ?? '',
      granted: json['granted'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}

class AccessDecision {
  const AccessDecision({
    required this.granted,
    required this.message,
    this.card,
    this.uid = '',
  });

  final bool granted;
  final String message;
  final SavedCard? card;
  final String uid;
}

const defaultGates = [
  Gate(id: 'main', name: 'Main gate', detail: 'Front entrance'),
  Gate(id: 'parking', name: 'Parking', detail: 'Vehicle entrance'),
  Gate(id: 'workshop', name: 'Workshop', detail: 'Staff floor'),
  Gate(id: 'server', name: 'Server room', detail: 'Restricted'),
];

var _nextId = 0;

String newId() {
  _nextId += 1;
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  return '$time$_nextId';
}

String? normalizeUid(String raw) {
  final hex = raw.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
  if (hex.length < 4 || hex.length > 32 || hex.length.isOdd) return null;
  return hex;
}

String formatUid(String uid) {
  final pairs = <String>[];
  for (var index = 0; index < uid.length; index += 2) {
    final end = index + 2 > uid.length ? uid.length : index + 2;
    pairs.add(uid.substring(index, end));
  }
  return pairs.join(' ');
}

String formatWhen(DateTime time) {
  final local = time.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour24 = local.hour;
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = hour24 >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, $hour:$minute $suffix';
}

SavedCard? _cardForUid(List<SavedCard> cards, String? uid) {
  if (uid == null) return null;
  for (final card in cards) {
    if (card.uid == uid) return card;
  }
  return null;
}

AccessDecision decideAccess({
  required Gate gate,
  required List<SavedCard> cards,
  String? hardwareUid,
  String? credentialUid,
}) {
  final hardwareCard = _cardForUid(cards, hardwareUid);
  final credentialCard = _cardForUid(cards, credentialUid);
  if (hardwareCard != null &&
      credentialCard != null &&
      hardwareCard.id != credentialCard.id) {
    return AccessDecision(
      granted: false,
      message: 'The chip id and the saved card number do not agree.',
      uid: credentialUid ?? hardwareUid ?? '',
    );
  }

  final card = credentialCard ?? hardwareCard;
  final uid = card?.uid ?? credentialUid ?? hardwareUid ?? '';
  if (card == null) {
    return AccessDecision(
      granted: false,
      message: 'This card is not saved on this phone.',
      uid: uid,
    );
  }
  if (!card.gateIds.contains(gate.id)) {
    return AccessDecision(
      granted: false,
      message: '${card.name} is not allowed through ${gate.name}.',
      card: card,
      uid: card.uid,
    );
  }
  return AccessDecision(
    granted: true,
    message: '${card.name} may enter ${gate.name}.',
    card: card,
    uid: card.uid,
  );
}

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'vault.dart';

class VaultScope extends InheritedNotifier<Vault> {
  const VaultScope({
    required Vault vault,
    required super.child,
    super.key,
  }) : super(notifier: vault);

  static Vault of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VaultScope>();
    assert(scope != null, 'VaultScope is missing above this widget');
    return scope!.notifier!;
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GATEKEY',
          style: TextStyle(
            color: blue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: mist, height: 1.35),
        ),
      ],
    );
  }
}

class CredentialFace extends StatelessWidget {
  const CredentialFace({
    required this.name,
    required this.uid,
    required this.caption,
    this.onTap,
    super.key,
  });

  final String name;
  final String uid;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paperHigh,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: line),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'GATEKEY',
                    style: TextStyle(
                      color: blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.contactless, color: sky),
                ],
              ),
              const SizedBox(height: 22),
              Container(width: 42, height: 3, color: sky),
              const SizedBox(height: 14),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatUid(uid),
                style: const TextStyle(
                  color: Color(0xFFD6E4F7),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(caption, style: const TextStyle(color: mist)),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String allowedGateLabel(List<Gate> gates, SavedCard card) {
  final names = [
    for (final gate in gates)
      if (card.gateIds.contains(gate.id)) gate.name,
  ];
  if (names.isEmpty) return 'No gates';
  if (names.length <= 2) return names.join(', ');
  return '${names.take(2).join(', ')} +${names.length - 2}';
}

Future<String?> promptForText(
  BuildContext context, {
  required String title,
  required String confirm,
  String hint = '',
  String initial = '',
  int maxLength = 40,
  TextCapitalization capitalization = TextCapitalization.sentences,
}) async {
  final controller = TextEditingController(text: initial);
  final value = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: maxLength,
          textCapitalization: capitalization,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (text) => Navigator.pop(context, text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(confirm),
          ),
        ],
      );
    },
  );
  controller.dispose();
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

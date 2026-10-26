import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'gate_reader_page.dart';

class GatesPage extends StatelessWidget {
  const GatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vault = VaultScope.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const PageHeader(
            title: 'Gates',
            subtitle: 'Open a gate, then tap a saved card to request access.',
          ),
          const SizedBox(height: 18),
          for (final gate in vault.gates) ...[
            _GateTile(gate: gate),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => _addGate(context),
            icon: const Icon(Icons.add),
            label: const Text('Add a gate'),
          ),
        ],
      ),
    );
  }

  Future<void> _addGate(BuildContext context) async {
    final name = await promptForText(
      context,
      title: 'New gate',
      confirm: 'Add',
      hint: 'Side door',
    );
    if (!context.mounted || name == null) return;
    final detail = await promptForText(
      context,
      title: 'Where is it?',
      confirm: 'Save',
      hint: 'North stair',
    );
    if (!context.mounted || detail == null) return;
    VaultScope.of(context).saveGate(
      Gate(id: newId(), name: name, detail: detail),
    );
  }
}

class _GateTile extends StatelessWidget {
  const _GateTile({required this.gate});

  final Gate gate;

  @override
  Widget build(BuildContext context) {
    final vault = VaultScope.of(context);
    final allowed = vault.cards
        .where((card) => card.gateIds.contains(gate.id))
        .length;

    return Material(
      color: paper,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => GateReaderPage(gateId: gate.id),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: line),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              const Icon(Icons.sensor_door_outlined, color: blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gate.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gate.detail,
                      style: const TextStyle(color: mist),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allowed == 1 ? '1 card allowed' : '$allowed cards allowed',
                      style: const TextStyle(color: sky, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _menu(context, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, String value) async {
    final vault = VaultScope.of(context);
    if (value == 'rename') {
      final name = await promptForText(
        context,
        title: 'Rename gate',
        confirm: 'Save',
        initial: gate.name,
      );
      if (!context.mounted || name == null) return;
      vault.saveGate(gate.copyWith(name: name));
      return;
    }
    final remove = await confirmAction(
      context,
      title: 'Delete ${gate.name}?',
      message: 'Saved cards will lose access to this gate.',
      confirm: 'Delete',
    );
    if (!context.mounted || !remove) return;
    vault.deleteGate(gate.id);
  }
}

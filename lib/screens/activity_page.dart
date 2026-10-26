import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vault = VaultScope.of(context);
    final events = vault.events;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: PageHeader(
                    title: 'Activity',
                    subtitle: 'Every card checked at a gate on this phone.',
                  ),
                ),
                if (events.isNotEmpty)
                  TextButton(
                    onPressed: () => _clear(context),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'No one has checked in yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mist, height: 1.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _EventTile(event: events[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _clear(BuildContext context) async {
    final clear = await confirmAction(
      context,
      title: 'Clear activity?',
      message: 'This removes the log kept on this phone.',
      confirm: 'Clear',
    );
    if (!context.mounted || !clear) return;
    VaultScope.of(context).clearEvents();
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final AccessEvent event;

  @override
  Widget build(BuildContext context) {
    final color = event.granted ? lime : coral;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.granted ? 'Granted' : 'Denied'} · ${event.gateName}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(event.cardName, style: const TextStyle(color: foam)),
                const SizedBox(height: 2),
                Text(
                  event.message,
                  style: const TextStyle(color: mist, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  formatWhen(event.at),
                  style: const TextStyle(color: mist, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

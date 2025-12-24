import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: cs.onTertiaryContainer, size: 20),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                'No internet connection',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: cs.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

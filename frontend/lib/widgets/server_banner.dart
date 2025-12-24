import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/constant/radii.dart';

class ServerErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ServerErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: cs.onErrorContainer),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onErrorContainer),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

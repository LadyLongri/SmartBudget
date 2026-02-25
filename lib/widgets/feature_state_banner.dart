import 'package:flutter/material.dart';

class FeatureStateBanner extends StatelessWidget {
  const FeatureStateBanner({
    super.key,
    required this.stateLabel,
    required this.message,
    this.icon,
    this.onRetry,
  });

  final String stateLabel;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, key: const Key('feature_state_icon')),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  stateLabel,
                  key: const Key('feature_state_label'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(message, key: const Key('feature_state_message')),
              ],
            ),
          ),
          if (onRetry != null)
            OutlinedButton(
              key: const Key('feature_state_retry'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

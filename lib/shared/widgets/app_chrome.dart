import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';

class MixSipBrand extends StatelessWidget {
  const MixSipBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 40 : 46,
          height: compact ? 40 : 46,
          decoration: BoxDecoration(
            color: AppColors.coffee,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.local_cafe_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MIX & SIP',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            if (!compact)
              Text(
                'Point of Sale',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
      ],
    );
  }
}

class AppBottomBar extends ConsumerWidget {
  const AppBottomBar({required this.currentPath, super.key});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final selectedColor = light ? AppColors.magenta : AppColors.amber;
    final unselectedColor = light ? AppColors.mauveGray : Colors.white54;
    final permissions =
        ref.watch(authControllerProvider).user?.permissions ?? const <String>{};
    final entries = <_NavEntry>[
      const _NavEntry('/', 'Home', Icons.home_rounded),
      if (permissions.contains('pos.menu'))
        const _NavEntry('/pos', 'New sale', Icons.add_shopping_cart_rounded),
      if (permissions.contains('orders.menu'))
        const _NavEntry('/orders', 'Orders', Icons.receipt_long_rounded),
      const _NavEntry('/settings', 'Settings', Icons.settings_rounded),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: light ? AppColors.paper : AppColors.ink,
          borderRadius: BorderRadius.circular(24),
          border: light ? Border.all(color: AppColors.blushBorder) : null,
          boxShadow: [
            BoxShadow(
              color:
                  light
                      ? AppColors.magenta.withValues(alpha: .12)
                      : Colors.black26,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children:
              entries.map((entry) {
                final selected = currentPath == entry.path;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap:
                        selected
                            ? null
                            : () {
                              if (entry.path == '/') {
                                context.go('/');
                              } else {
                                context.push(entry.path);
                              }
                            },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          entry.icon,
                          color: selected ? selectedColor : unselectedColor,
                          size: 22,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          entry.label,
                          maxLines: 1,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: selected ? selectedColor : unselectedColor,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NavEntry {
  const _NavEntry(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

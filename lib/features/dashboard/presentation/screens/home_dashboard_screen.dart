import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user!;
    final permissions = user.permissions;
    final role = user.roles.isEmpty ? 'Team member' : user.roles.join(' · ');
    final actions = <_HomeAction>[
      if (permissions.contains('pos.menu'))
        _HomeAction(
          title: 'New sale',
          subtitle: 'Create an order and take payment',
          label: 'START SELLING',
          icon: Icons.point_of_sale_rounded,
          color: AppColors.rose,
          featured: true,
          onTap: () => context.push('/pos'),
        ),
      if (permissions.contains('orders.menu'))
        _HomeAction(
          title: 'Orders',
          subtitle: 'Track pending, due and completed sales',
          label: 'SALES HISTORY',
          icon: Icons.receipt_long_rounded,
          color: AppColors.sage,
          onTap: () => context.push('/orders'),
        ),
      _HomeAction(
        title: 'Punch clock',
        subtitle: 'Punch in or out and view today’s activity',
        label: 'ATTENDANCE',
        icon: Icons.fingerprint_rounded,
        color: AppColors.magenta,
        onTap: () => context.push('/punch'),
      ),
      _HomeAction(
        title: 'Register',
        subtitle: 'Count, reconcile and close today’s cash',
        label: 'CASH CONTROL',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.coral,
        onTap: () => context.push('/register'),
      ),
    ];

    return Scaffold(
      bottomNavigationBar: const AppBottomBar(currentPath: '/'),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                _TopBar(name: user.name),
                const SizedBox(height: 22),
                _WelcomeHero(name: user.name, role: role),
                const SizedBox(height: 28),
                _SectionHeader(count: actions.length),
                const SizedBox(height: 14),
                _ActionsLayout(actions: actions),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const MixSipBrand(),
      const Spacer(),
      Material(
        color: Theme.of(context).cardTheme.color,
        shape: StadiumBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => context.push('/settings'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.rose,
                  foregroundColor: Colors.white,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.name, required this.role});
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              dark
                  ? const [Color(0xFF3A2531), Color(0xFF2A222E)]
                  : const [Color(0xFFFFD9E9), Color(0xFFF1E0FA)],
        ),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.magenta.withValues(alpha: dark ? .08 : .12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(right: -32, top: -52, child: _HeroOrb(size: 180)),
          const Positioned(
            right: 30,
            bottom: -68,
            child: _HeroOrb(size: 150, coral: true),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: dark ? .10 : .68,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'TODAY’S WORKSPACE',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: dark ? AppColors.blush : AppColors.plum,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Hi, $firstName!',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$role · Ready for service',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: dark ? .10 : .78),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.local_cafe_rounded,
                    size: 36,
                    color: AppColors.rose,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, this.coral = false});
  final double size;
  final bool coral;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: (coral ? AppColors.coral : AppColors.rose).withValues(alpha: .13),
      shape: BoxShape.circle,
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Everything you need for today',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count tools',
          style: const TextStyle(
            color: AppColors.plum,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _ActionsLayout extends StatelessWidget {
  const _ActionsLayout({required this.actions});
  final List<_HomeAction> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 820 ? 4 : 2;
      const gap = 12.0;
      final cardWidth =
          (constraints.maxWidth - (gap * (columns - 1))) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final action in actions)
            SizedBox(width: cardWidth, child: _ActionCard(action: action)),
        ],
      );
    },
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});
  final _HomeAction action;

  @override
  Widget build(BuildContext context) {
    final featured = action.featured;
    final foreground = featured ? Colors.white : null;
    return Container(
      height: 126,
      decoration:
          featured
              ? BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.rose, AppColors.magenta],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.magenta.withValues(alpha: .16),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              )
              : null,
      child: Card(
        margin: EdgeInsets.zero,
        color: featured ? Colors.transparent : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side:
              featured
                  ? BorderSide.none
                  : BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
        ),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ActionIcon(action: action, featured: featured),
                    const Spacer(),
                    Icon(
                      Icons.north_east_rounded,
                      size: 18,
                      color:
                          featured
                              ? Colors.white70
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        featured
                            ? Colors.white70
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.action, this.featured = false});
  final _HomeAction action;
  final bool featured;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color:
          featured
              ? Colors.white.withValues(alpha: .18)
              : action.color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      action.icon,
      color: featured ? Colors.white : action.color,
      size: 21,
    ),
  );
}

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.featured = false,
  });
  final String title;
  final String subtitle;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool featured;
}

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

    final modules = <_DashboardModule>[
      if (permissions.contains('pos.menu'))
        _DashboardModule(
          title: 'New sale',
          subtitle: 'Start an order and take payment',
          icon: Icons.point_of_sale_rounded,
          color: AppColors.coffee,
          onTap: () => context.go('/pos'),
        ),
      if (permissions.contains('orders.menu'))
        _DashboardModule(
          title: 'Orders',
          subtitle: 'Pending, due and completed sales',
          icon: Icons.receipt_long_rounded,
          color: AppColors.sage,
          onTap: () => context.go('/orders'),
        ),
      _DashboardModule(
        title: 'Register balance',
        subtitle: 'Open, expense and close cash count',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.amber,
        onTap: () => context.go('/register'),
      ),
    ];

    return Scaffold(
      bottomNavigationBar: const AppBottomBar(currentPath: '/'),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(child: _TopBar(name: user.name)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _WelcomePanel(name: user.name, role: role),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Quick actions',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${modules.length} available',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = width >= 900 ? 3 : 2;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: width >= 580 ? 164 : 190,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ModuleCard(modules[index]),
                          childCount: modules.length,
                        ),
                      );
                    },
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const MixSipBrand(),
      const Spacer(),
      Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.coffee,
              foregroundColor: Colors.white,
              child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
            ),
            const SizedBox(width: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors:
              dark
                  ? const [Color(0xFF352C25), Color(0xFF253230)]
                  : const [
                    Color(0xFFFFDFEC),
                    Color(0xFFF3E5FA),
                    Color(0xFFFFE8DF),
                  ],
        ),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME BACK',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color:
                        dark ? const Color(0xFFE2BB96) : AppColors.coffeeDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$role · Ready for today’s service',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color:
                  dark ? Colors.white10 : Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_cafe_rounded,
              size: 34,
              color: AppColors.coffee,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard(this.module);

  final _DashboardModule module;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 260;
      return Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: module.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child:
                compact
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ModuleIcon(module: module, compact: true),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          module.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          module.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        _ModuleIcon(module: module),
                        const SizedBox(width: 17),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                module.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                module.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
          ),
        ),
      );
    },
  );
}

class _ModuleIcon extends StatelessWidget {
  const _ModuleIcon({required this.module, this.compact = false});
  final _DashboardModule module;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 46 : 58,
    height: compact ? 46 : 58,
    decoration: BoxDecoration(
      color: module.color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(compact ? 13 : 16),
    ),
    child: Icon(module.icon, color: module.color, size: compact ? 24 : 28),
  );
}

class _DashboardModule {
  const _DashboardModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

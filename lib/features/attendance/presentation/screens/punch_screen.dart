import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_error_parser.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

class PunchScreen extends ConsumerStatefulWidget {
  const PunchScreen({super.key});

  @override
  ConsumerState<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends ConsumerState<PunchScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;
  bool saving = false;
  DateTime now = DateTime.now();
  Timer? clock;

  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
    _load();
  }

  @override
  void dispose() {
    clock?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .dio
          .get<Map<String, dynamic>>('/attendance/self');
      if (mounted) {
        setState(() {
          data = response.data!['data'] as Map<String, dynamic>;
          error = null;
          loading = false;
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = ApiErrorParser.parse(exception).message;
          loading = false;
        });
      }
    }
  }

  Future<void> _punch() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .dio
          .post<Map<String, dynamic>>('/attendance/self/punch');
      if (mounted) {
        setState(() {
          data = response.data!['data'] as Map<String, dynamic>;
          saving = false;
        });
        final type = data?['is_punched_in'] == true ? 'in' : 'out';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('You are punched $type.')));
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = ApiErrorParser.parse(exception).message;
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final punchedIn = data?['is_punched_in'] == true;
    final punches = data?['punches'] as List? ?? const [];
    final employeeName = data?['employee_name']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Punch clock')),
      bottomNavigationBar: const AppBottomBar(currentPath: '/punch'),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  children: [
                    _StatusCard(
                      punchedIn: punchedIn,
                      employeeName: employeeName,
                      saving: saving,
                      enabled: data != null,
                      now: now,
                      onPunch: _punch,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(message: error!, onRetry: _load),
                    ],
                    const SizedBox(height: 26),
                    Text(
                      'Today’s activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (punches.isEmpty)
                      const AppEmptyState(
                        icon: Icons.schedule_rounded,
                        title: 'No punches yet',
                        message: 'Your punches for today will appear here.',
                      )
                    else
                      Card(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var index = 0; index < punches.length; index++)
                              _PunchRow(
                                punch: punches[index] as Map<String, dynamic>,
                                showDivider: index < punches.length - 1,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.punchedIn,
    required this.employeeName,
    required this.saving,
    required this.enabled,
    required this.now,
    required this.onPunch,
  });

  final bool punchedIn;
  final String employeeName;
  final bool saving;
  final bool enabled;
  final DateTime now;
  final VoidCallback onPunch;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            punchedIn
                ? const [AppColors.rose, AppColors.magenta]
                : const [Color(0xFFFFDDEA), Color(0xFFF1E2FA)],
      ),
    ),
    child: Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            punchedIn ? Icons.work_history_rounded : Icons.fingerprint_rounded,
            size: 38,
            color: AppColors.magenta,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          punchedIn ? 'You’re punched in' : 'Ready to begin?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: punchedIn ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          employeeName,
          style: TextStyle(
            color: punchedIn ? Colors.white70 : AppColors.mauveGray,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _formatClock(now),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: punchedIn ? Colors.white : AppColors.plum,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        Text(
          _formatDate(now),
          style: TextStyle(
            color: punchedIn ? Colors.white70 : AppColors.mauveGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: saving || !enabled ? null : onPunch,
          icon:
              saving
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Icon(
                    punchedIn ? Icons.logout_rounded : Icons.login_rounded,
                  ),
          label: Text(
            saving
                ? 'Recording...'
                : punchedIn
                ? 'Punch out'
                : 'Punch in',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: punchedIn ? Colors.white : AppColors.magenta,
            foregroundColor: punchedIn ? AppColors.magenta : Colors.white,
            minimumSize: const Size.fromHeight(54),
          ),
        ),
      ],
    ),
  );

  String _formatClock(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatDate(DateTime value) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} ${value.day}';
  }
}

class _PunchRow extends StatelessWidget {
  const _PunchRow({required this.punch, required this.showDivider});
  final Map<String, dynamic> punch;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final type = punch['type']?.toString() ?? '';
    final parsed =
        DateTime.tryParse(punch['time']?.toString() ?? '')?.toLocal();
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: type == 'IN' ? AppColors.blush : AppColors.lilac,
            child: Icon(
              type == 'IN' ? Icons.login_rounded : Icons.logout_rounded,
              color: type == 'IN' ? AppColors.rose : AppColors.sage,
            ),
          ),
          title: Text(
            type == 'IN' ? 'Punched in' : 'Punched out',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          trailing: Text(
            parsed == null ? '--:--' : _formatTime(parsed),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 72),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 880;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          if (wide)
                            const Expanded(flex: 5, child: _LoginWelcome()),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: EdgeInsets.all(wide ? 48 : 28),
                              child: Form(
                                key: _form,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (!wide) ...[
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: MixSipBrand(),
                                      ),
                                      const SizedBox(height: 36),
                                    ],
                                    Text(
                                      'Welcome back',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sign in to start taking orders.',
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    TextFormField(
                                      controller: _username,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        prefixIcon: Icon(
                                          Icons.person_outline_rounded,
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value == null ||
                                                      value.trim().isEmpty
                                                  ? 'Enter your username.'
                                                  : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _password,
                                      obscureText: _obscure,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed:
                                              () => setState(
                                                () => _obscure = !_obscure,
                                              ),
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Enter your password.'
                                                  : null,
                                      onFieldSubmitted:
                                          (_) => _submit(auth.submitting),
                                    ),
                                    if (auth.error != null) ...[
                                      const SizedBox(height: 14),
                                      ErrorBanner(message: auth.error!.message),
                                    ],
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed:
                                          auth.submitting
                                              ? null
                                              : () => _submit(false),
                                      icon:
                                          auth.submitting
                                              ? const SizedBox.square(
                                                dimension: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : const Icon(
                                                Icons.arrow_forward_rounded,
                                              ),
                                      label: const Text('Sign in'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submit(bool busy) {
    if (busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(authControllerProvider.notifier)
        .login(_username.text.trim(), _password.text);
  }
}

class _LoginWelcome extends StatelessWidget {
  const _LoginWelcome();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(48),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFDDEA), Color(0xFFF1E2FA), Color(0xFFFFE6DD)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MixSipBrand(),
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.point_of_sale_rounded,
            size: 38,
            color: AppColors.coffee,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Simple service.\nSmooth checkout.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Everything your team needs to create sales and manage orders.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.sage,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

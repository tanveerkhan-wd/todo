import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/security_provider.dart';
import '../theme/tokens.dart';

/// Full-screen lock shown on app start when biometric lock is enabled.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _busy = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _busy = true;
      _message = '';
    });

    final service = ref.read(biometricServiceProvider);
    final ok = await service.authenticate();

    setState(() => _busy = false);

    if (ok && mounted) {
      ref.read(biometricUnlockedProvider.notifier).state = true;
    } else if (mounted) {
      setState(() => _message = 'Authentication failed. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'App lock icon',
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Semantics(
                label: 'App title',
                child: Text(
                  'Todo',
                  style: theme.textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              if (_busy)
                Semantics(
                  label: 'Authenticating',
                  child: const CircularProgressIndicator(),
                )
              else
                Semantics(
                  label: 'Unlock button',
                  child: FilledButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Unlock'),
                  ),
                ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                Semantics(
                  label: _message,
                  child: Text(
                    _message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

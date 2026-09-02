import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../controllers/auth_providers.dart';

/// Tela de segurança — MFA e autenticação biométrica.
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bioAvailable =
        await ref.read(biometricAuthUseCaseProvider).isAvailable();
    final bioEnabled =
        await ref.read(biometricAuthUseCaseProvider).isEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = bioAvailable;
        _biometricEnabled = bioEnabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBiometric() async {
    if (_biometricEnabled) {
      await ref.read(biometricAuthUseCaseProvider).disable();
      setState(() => _biometricEnabled = false);
    } else {
      final auth = await ref.read(biometricAuthUseCaseProvider).authenticate();
      if (auth) {
        await ref.read(biometricAuthUseCaseProvider).enable();
        if (mounted) setState(() => _biometricEnabled = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segurança'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Biometria.
                if (_biometricAvailable)
                  _SecurityTile(
                    icon: Icons.fingerprint_outlined,
                    title: 'Autenticação Biométrica',
                    subtitle: _biometricEnabled
                        ? 'Ativada — Impressão digital ou rosto'
                        : 'Use impressão digital ou reconhecimento facial',
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: (_) => _toggleBiometric(),
                    ),
                  ),
                if (!_biometricAvailable) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _SecurityTile(
                    icon: Icons.fingerprint_outlined,
                    title: 'Autenticação Biométrica',
                    subtitle: 'Não disponível neste dispositivo',
                    trailing: const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

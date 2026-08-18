import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n_ext.dart';
import '../controllers/auth_providers.dart';

/// Botão de sair da conta (ícone de logout).
class SignOutButton extends ConsumerWidget {
 const SignOutButton({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 return IconButton(
 tooltip: context.l10n.commonSignOut,
 icon: const Icon(Icons.logout),
 onPressed: () => ref.read(signOutUseCaseProvider).call(),
 );
 }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/auth_redirect.dart';
import 'auth_gate.dart';

/// Friendly landing page for errors returned by Supabase auth links.
///
/// Supabase sends expired/invalid confirmation links back to the configured
/// site URL with an error in the query or fragment. This page avoids exposing
/// that raw URL and lets an unconfirmed customer request a fresh link.
class AuthLinkErrorScreen extends StatefulWidget {
  const AuthLinkErrorScreen({super.key, required this.errorCode});

  final String errorCode;

  @override
  State<AuthLinkErrorScreen> createState() => _AuthLinkErrorScreenState();
}

class _AuthLinkErrorScreenState extends State<AuthLinkErrorScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _message;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'Introduza um endereço de email válido.');
      return;
    }

    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: authRedirectUrl(),
      );
      if (!mounted) return;
      setState(() {
        _sent = true;
        _message =
            'Se existir um registo por confirmar para este email, '
            'enviaremos um novo link.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.statusCode == '429'
            ? 'Aguarde um pouco antes de pedir outro link.'
            : 'Não foi possível reenviar agora. Verifique o email e tente novamente.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message =
            'Não foi possível reenviar agora. Tente novamente mais tarde.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = widget.errorCode == 'otp_expired';
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                expired ? Icons.mark_email_unread_outlined : Icons.link_off,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                expired
                    ? 'Este link expirou'
                    : 'Não foi possível confirmar o email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                expired
                    ? 'Os links de confirmação são de utilização única e podem expirar. Peça um novo link para concluir o registo.'
                    : 'O link não é válido ou já foi utilizado. Peça um novo link para concluir o registo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email usado no registo',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_sent) setState(() => _sent = false);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _sending || _sent ? null : _resendConfirmation,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_sent ? 'Link reenviado' : 'Reenviar confirmação'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const AuthGate()),
                  (_) => false,
                ),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/navigation/app_routes.dart';
import '../config/supabase_config.dart';
import '../observability/crash_reporting.dart';

/// Trata os deep links de autenticação (confirmação de e-mail / magic link /
/// OAuth com PKCE): quando o usuário toca no link do e-mail
/// (`tareqo://callback`), o OS abre o app e esta URI é entregue ao
/// gotrue via [AuthClient.getSessionFromUrl] — que troca o code PKCE, grava
/// a sessão e o stream de sessão reage sozinho (o [AuthGate] troca de tela).
///
/// **Por que existe (fix Aug 8):** antes, o `site_url` do projeto era
/// `http://localhost:3000` e o app não tinha scheme registrado — o link de
/// confirmação não levava a lugar nenhum e o e-mail nunca confirmava
/// (`email_confirmed_at` ficava NULL, sem tenant pending no painel do admin).
///
/// O registro do scheme vive em:
/// - Android: `AndroidManifest.xml` (intent-filter `tareqo://callback`);
/// - iOS: `Info.plist` (`CFBundleURLTypes` → `tareqo`);
/// - Supabase: `site_url` = `tareqo://callback` (Authentication).
abstract final class DeepLinkHandler {
  /// Scheme do app registrado no AndroidManifest.xml / Info.plist
  /// (legado — o fluxo novo é App Links/Universal Links, auditoria M4).
  static const String _scheme = 'tareqo';

  /// Host de callback do gotrue (OAuth PKCE / magic link).
  static const String _callbackHost = 'callback';

  /// Domínio HTTPS do site (App Links / Universal Links): o gotrue
  /// também aceita `https://tareqo.app/callback` quando o `site_url` do
  /// Supabase é configurado para ele (ver website/.well-known e
  /// docs/13-build-e-publicacao — passos de infra M4).
  static const String _webHost = 'tareqo.app';

  static const String _callbackPath = '/callback';

  /// Valida se [uri] é um deep link de autenticação legítimo.
  ///
  /// Aceita `tareqo://callback?code=...` (scheme legado, com validação
  /// de scheme+host contra hijack — auditoria V12) ou
  /// `https://tareqo.app/callback?code=...` (App Links/Universal Links,
  /// verificados pelo SO — auditoria M4). Qualquer outra origem é
  /// rejeitada.
  static bool isAuthCallbackUri(Uri uri) {
    if (uri.scheme == _scheme && uri.host == _callbackHost) {
      return true;
    }
    return uri.scheme == 'https' &&
        uri.host == _webHost &&
        uri.path == _callbackPath;
  }

  static AppLinks? _appLinks;
  static bool _listening = false;

  /// Contexto para navegação de deep links internos (`tareqo://go/<rota>`).
  /// Registado pelo `TareqoApp` (acima do Navigator).
  static BuildContext? _navContext;

  /// Regista o contexto de navegação (chamado pelo `TareqoApp`).
  static void attachNavigator(BuildContext context) {
    _navContext = context;
  }

  /// Inicia o listener de deep links (chamado no [AuthGate]). Idempotente.
  ///
  /// Todo o corpo é protegido: em testes de widget o plugin não tem
  /// plataforma (MissingPluginException) e não deve quebrar o fluxo.
  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured || _listening) return;
    try {
      final appLinks = _appLinks ??= AppLinks();

      // Cold start: o app foi ABERTO pelo link (getInitialLink).
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        if (isAuthCallbackUri(initialUri)) {
          // Auth (gotrue/PKCE) — apenas callback legítimo.
          await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
        } else if (_navContext != null) {
          // U-09: deep link interno `tareqo://go/<rota>` — navega sem sair.
          AppRoutes.handleGoDeepLink(_navContext!, initialUri);
        }
      }

      // Warm start: o app já estava aberto e o link foi tocado.
      appLinks.uriLinkStream.listen(
        (uri) async {
          if (isAuthCallbackUri(uri)) {
            try {
              await Supabase.instance.client.auth.getSessionFromUrl(uri);
            } catch (error, stackTrace) {
              CrashReporting.capture(
                error,
                stackTrace,
                hint: 'Deep link de autenticação (stream)',
              );
            }
            return;
          }
          // U-09: link interno (não-auth) — navega se houver contexto.
          if (_navContext != null) {
            AppRoutes.handleGoDeepLink(_navContext!, uri);
          }
        },
        // Erro no STREAM em si (canal da plataforma): sem handler vira um
        // erro de zona não tratado — loga e segue.
        onError: (Object error, StackTrace stackTrace) {
          CrashReporting.capture(
            error,
            stackTrace,
            hint: 'Deep link de autenticação (stream error)',
          );
        },
      );

      // Só marca como ativo DEPOIS do listener registrado: uma falha no
      // primeiro init (ex.: em testes, sem Supabase.initialize) não deixa
      // a flag presa e uma nova chamada pode tentar de novo.
      _listening = true;
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Deep link de autenticação (init)',
      );
    }
  }
}

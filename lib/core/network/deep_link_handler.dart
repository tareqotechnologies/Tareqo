import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../observability/crash_reporting.dart';

/// Trata os deep links de autenticação (confirmação de e-mail / magic link /
/// OAuth com PKCE): quando o usuário toca no link do e-mail
/// (`dumbhanengue://callback`), o OS abre o app e esta URI é entregue ao
/// gotrue via [AuthClient.getSessionFromUrl] — que troca o code PKCE, grava
/// a sessão e o stream de sessão reage sozinho (o [AuthGate] troca de tela).
///
/// **Por que existe (fix Aug 8):** antes, o `site_url` do projeto era
/// `http://localhost:3000` e o app não tinha scheme registrado — o link de
/// confirmação não levava a lugar nenhum e o e-mail nunca confirmava
/// (`email_confirmed_at` ficava NULL, sem tenant pending no painel do admin).
///
/// O registro do scheme vive em:
/// - Android: `AndroidManifest.xml` (intent-filter `dumbhanengue://callback`);
/// - iOS: `Info.plist` (`CFBundleURLTypes` → `dumbhanengue`);
/// - Supabase: `site_url` = `dumbhanengue://callback` (Authentication).
abstract final class DeepLinkHandler {
 static AppLinks? _appLinks;
 static bool _listening = false;

 /// Inicia o listener de deep links (chamado no [AuthGate]). Idempotente.
 ///
 /// Todo o corpo é protegido: em testes de widget o plugin não tem
 /// plataforma (MissingPluginException) e não deve quebrar o fluxo.
 static Future<void> init() async {
 if (!SupabaseConfig.isConfigured || _listening) return;
 try {
 final appLinks = _appLinks ??= AppLinks();

 // Cold start: o app foi ABERTO pelo link (getInitialLink). Entrega a
 // URI ao gotrue para concluir a confirmação/exchange do PKCE.
 final initialUri = await appLinks.getInitialLink();
 if (initialUri != null) {
 await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
 }

 // Warm start: o app já estava aberto e o link foi tocado.
 appLinks.uriLinkStream.listen(
 (uri) async {
 try {
 await Supabase.instance.client.auth.getSessionFromUrl(uri);
 } catch (error, stackTrace) {
 CrashReporting.capture(
 error,
 stackTrace,
 hint: 'Deep link de autenticação (stream)',
 );
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

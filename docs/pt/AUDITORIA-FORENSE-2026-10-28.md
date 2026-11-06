# Auditoria forense Flutter/Dart — TAREQO ERP

**Data da execução:** 28/10/2026  
**Escopo:** código Flutter/Dart, configuração Android/iOS/Windows/web, dependências, SQL/Supabase, CI/CD, testes e capacidade de build deste checkout.  
**Método:** inspeção de arquivos, buscas estáticas direcionadas e comandos realmente executados no ambiente disponível. Nenhum arquivo de código/configuração foi intencionalmente alterado pela auditoria.  
**Padrões de referência:** OWASP MASVS/MASTG (armazenamento, autenticação, rede e plataforma); não foi executado um teste de conformidade formal.

> **Limitação de integridade do checkout:** o diretório já continha numerosas alterações staged/unstaged e arquivos não rastreados antes da retomada desta auditoria. A auditoria não criou essas alterações e não tentou revertê-las. `pubspec.lock` já aparecia modificado; não é possível atribuir sua origem a partir das evidências preservadas. Os resultados descrevem o estado inspecionado, não necessariamente um commit limpo.

## A. Resumo executivo

O projeto tem arquitetura Flutter/Dart extensa (camadas presentation/domain/data, Riverpod/GetIt, SQLite local e Supabase/Postgres em modo SaaS), 258 arquivos `*_test.dart`, 3 testes de integração e pipelines de CI/release. Há controles importantes presentes no código: sessão/PKCE no Keychain/Keystore nativo, payload da outbox cifrado com AES-GCM no caminho nativo, TLS com âncora WE1 fail-closed no cliente nativo do Supabase, RLS em tabelas do schema, RPCs `SECURITY DEFINER` com `search_path` fixo, flavors e guarda que exige credenciais explícitas em release.

**Parecer: REPROVADO para release mobile/lojas no estado verificado; INCONCLUSIVO quanto à segurança global.** O código analisado em `lib/` passou `flutter analyze`, mas o `flutter analyze` global falha por dois probes não rastreados sob `tool/`. O manifesto Android principal não declara `INTERNET`, impedindo o acesso à rede no APK/AAB resultante (achado confirmado por inspeção; não foi possível gerar manifest merged sem SDK Android). Android não pôde compilar porque o SDK não está instalado/configurado. iOS não pôde compilar nesta máquina Windows sem Xcode/macOS. Web release e Windows release foram compilados e os artefatos foram conferidos.

Riscos adicionais: SQLite principal contém dados financeiros/PII sem SQLCipher; a suposta exclusão de backup iOS não tem implementação Swift nem chamada encontrada; o onboarding de funcionários recebe uma senha escolhida pelo proprietário e a envia à RPC. Além disso, o estado de release signing/segredos do checkout atual está incompleto (sem keystore local), e o banco atual não foi validado contra SQL de produção. Não se conclui que o projeto esteja seguro com base apenas na análise estática/testes unitários.

### Estado final por dimensão

| Dimensão | Parecer |
|---|---|
| Projeto analisado | Sim, inspeção ampla e dirigida dos componentes listados na seção B; não revisão manual linha a linha dos 560 arquivos Dart e todo SQL. |
| Testes executados | Sim: testes direcionados 61/61 passam; suíte completa iniciou anteriormente, excedeu 600 s sem resultado verificável. |
| Análise estática | `lib/`: aprovada (0 issues); global: reprovada, erros em `tool/probe_sym.dart`. |
| Build | Web release e Windows release aprovados; APK debug / AAB prod bloqueados; iOS não executável neste host. |
| Segurança | Não validada integralmente; achados e controles avaliados apenas em código/configuração, sem pentest, aparelho, scanner de dependências ou validação de backend/contas. |
| Código alterado | Nenhuma mudança intencional da auditoria. Builds criaram artefatos em `build/`; arquivos gerados não foram limpos para preservar checkout. `pubspec.lock` estava modificado no início da retomada. |

## B. Inventário técnico e limitações

### Estrutura observada

- `lib/`: 560 arquivos — Flutter/Dart, Clean Architecture, Riverpod, GetIt, Supabase, SQLite.
- `test/`: 311 arquivos no total, contendo 258 nomes `*_test.dart`.
- `integration_test/`: 3 arquivos.
- `android/`: 56 arquivos; Gradle Kotlin DSL, flavors `dev`/`prod`, AGP 9.3.2, Kotlin 2.3.20, JDK target 17, Gradle wrapper configurado em `gradle-wrapper.properties` para Gradle 9.5.0. Não há wrapper executável/arquivo JAR (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar` ausentes).
- `ios/`: 56 arquivos, projeto Xcode, deployment target 13.0, `AppDelegate.swift`, `Info.plist`; sem `Podfile` versionado no estado atual e pipeline/README documenta uso de SPM em workflow IPA.
- `windows/`: build desktop nativo; `web/`: Flutter web.
- `supabase/`: schema SQL, upgrade SQL, scripts e verificações; projeto usa Postgres/Supabase com RLS/RPCs.
- `.github/workflows/`: 5 workflows, incluindo CI, release Android, iOS, IPA e OSV.
- Dependências principais incluem `supabase_flutter`, `flutter_secure_storage`, `sqlite3`, `sentry_flutter`, `app_links`, `mobile_scanner`, `cryptography`, `Riverpod`, `GetIt`.

### Ferramentas/ambiente

- Windows 10 x86_64, shell MSYS2/Git Bash.
- Flutter 3.47.7 stable (framework revision abaf9c5237, 08/10/2026); Dart 3.13.5.
- Java/OpenJDK 27 disponível. Projeto usa toolchain-alvo Java 17; JDK 17 não foi encontrado.
- `gradle`, `adb`, Android SDK, `xcodebuild`, CocoaPods, `osv-scanner`, `gitleaks` e `trivy` indisponíveis.
- `flutter doctor -v` relatou Android Studio apontado para caminho inválido e erro do wrapper Flutter procurando `C:\src\flutter\bin\internal\update_engine_version.ps1`, inexistente. O erro do wrapper também aparece em outras chamadas, mas vários comandos Flutter ainda completaram.
- A compilação Windows imprimiu aviso `Nuget.exe not found`/tentativa de usar cache, mas terminou com exit code 0 e produziu EXE.
- Não foram executadas chamadas ao Supabase, painel de produção, lojas Apple/Google ou APIs de terceiros. A presença das variáveis locais foi verificada sem imprimir valores.

### Componentes revisados por evidência

`pubspec.yaml`/`pubspec.lock`, `analysis_options.yaml`, workflows, Gradle/manifest Android, Xcode project/Info.plist/Swift, configuração de flavors/segredos, configuração Supabase e TLS, sessão segura, outbox cifrada, database SQLite, deep links, logging/Sentry, fluxos de cadastro de funcionário, schemas/RPC/RLS, documentação e scripts de build/release. Documentos antigos de auditoria foram tratados como contexto histórico, não como prova atual.

## C. Matriz de achados

### F-01 — Permissão de rede ausente no manifesto Android principal

- **Severidade:** ALTA (bloqueador funcional de release Android); **confiança:** alta.
- **Local:** [AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml); manifests debug/profile em `android/app/src/debug/AndroidManifest.xml` e `android/app/src/profile/AndroidManifest.xml`.
- **Evidência reproduzível:** buscas em `android/app/src/main` não encontraram `INTERNET` nem referência a `android.permission.INTERNET`; a permissão aparece somente nos manifests `debug` e `profile`, acompanhada de comentário que a justifica apenas para desenvolvimento. `lib/core/network/supabase_bootstrap.dart` inicializa Supabase; o app depende de rede para autenticação/serviços SaaS.
- **Causa:** permissão declarada apenas em source sets de desenvolvimento; a variante release não herda o manifest de debug/profile.
- **Impacto:** em Android release, o app não pode abrir conexões de rede ao Supabase/Sentry; login e operações online falham mesmo com URL/chave corretas. APK/AAB pode compilar, mas funcionalidades essenciais não funcionam.
- **Pré-requisito:** qualquer operação Android release que exija conectividade.
- **Reprodução segura:** instalar o APK release em emulador/dispositivo, verificar o manifest merged (`aapt dump permissions`) e observar falha de rede sem modificar dados de produção.
- **Correção recomendada:** adicionar `android.permission.INTERNET` em `src/main/AndroidManifest.xml`; gerar manifest merged de release e validar login/endpoint em backend de teste.
- **Regressão:** `flutter build apk --release --flavor dev ...`; conferir permissão no APK com `aapt`; teste de conectividade autorizado contra ambiente dev.

### F-02 — SQLite principal e PII armazenados sem criptografia de banco

- **Severidade:** MÉDIA; **confiança:** alta quanto à ausência de criptografia; explorabilidade depende de acesso físico/root, extração de backup ou comprometimento do dispositivo.
- **Local:** [app_database_io.dart](../../lib/core/database/app_database_io.dart#L54-L62), schema SQLite (tabelas de vendas/clientes; campos `person_name`, entre outros). Outbox: [pending_op_queue_sqlite_impl.dart](../../lib/data/datasources/local/pending_op_queue_sqlite_impl.dart#L20-L64).
- **Evidência:** `sqlite3.open(.../tareqo.db)` sem `PRAGMA key` ou driver SQLCipher; schema local contém dados financeiros e pessoais. Há AES-GCM na outbox e chave em secure storage, mas isso não cifra as demais tabelas.
- **Causa:** proteção aplicada somente aos payloads pendentes; DB SQLite inteiro permanece plaintext.
- **Impacto:** quem obtiver o arquivo do sandbox (dispositivo comprometido/root/jailbreak, extração forense ou cópia acessível) pode ler histórico financeiro e PII. Risco mitigado parcialmente por isolamento do SO e backups Android desativados.
- **Pré-requisito:** acesso ao arquivo de dados/dispositivo ou backup obtido; não é exploração remota demonstrada.
- **Reprodução segura:** em aparelho de teste, criar dados sintéticos, copiar DB por mecanismo autorizado e confirmar que SQLite padrão o abre.
- **Correção:** avaliar SQLCipher compatível com `sqlite3` 3.x/native assets, chave aleatória no Keychain/Keystore e migração transacional de DB antigo; elaborar estratégia de recuperação se chave for perdida.
- **Regressão:** teste migração com DB legado sintético, reopen com chave, falha sem chave e inspeção do arquivo para assegurar que texto sintético não aparece.

### F-03 — Exclusão de backup iOS documentada mas não implementada/acionada

- **Severidade:** MÉDIA (risco de privacidade em backup); **confiança:** alta sobre ausência de handler/call site no checkout inspecionado.
- **Local:** [backup_exclusion_io.dart](../../lib/core/platform/backup_exclusion_io.dart#L15-L30), [AppDelegate.swift](../../ios/Runner/AppDelegate.swift), [service_locator.dart](../../lib/core/di/service_locator.dart#L288).
- **Evidência:** Dart declara `MethodChannel('dev.tareqo/backup_exclusion')` e o facade promete excluir DB/fotos; buscas em `ios/` não encontraram `excludeFromBackup`, o channel ou `NSURLIsExcludedFromBackupKey`; busca em `lib/` localizou declaração/implementação, mas nenhum call site de `excludePathFromBackup`. `AppDelegate.swift` somente registra plugins.
- **Causa:** implementação nativa e inicialização/chamadas não estão presentes no estado atual, apesar da documentação anterior declarar o controle concluído.
- **Impacto:** dados em `Documents` podem entrar em backup iCloud/iTunes conforme comportamento iOS e política do app; isso aumenta cópias/retensão de dados fora do dispositivo. Não foi testado em aparelho Apple.
- **Pré-requisito:** iOS e backup/configuração compatível.
- **Reprodução segura:** inspeção estática já reproduz ausência; confirmação dinâmica requer Xcode/dispositivo e leitura do atributo de backup em pasta de dados de teste.
- **Correção:** implementar handler Swift robusto para arquivo/diretório, chamar após abrir/garantir DB e ao criar diretório de imagens, tratar erros observáveis (não silenciosos quando controle obrigatório) e revisar ciclo de vida.
- **Regressão:** teste nativo iOS confirma atributo `NSURLIsExcludedFromBackupKey` no DB e diretório; Flutter unit test confirma invocação no bootstrap.

### F-04 — Senha de funcionário escolhida pelo proprietário e enviada na RPC

- **Severidade:** MÉDIA; **confiança:** alta.
- **Local:** [stores_widgets_sheets.dart](../../lib/presentation/screens/stores/stores_widgets_sheets.dart#L200-L260), [supabase_employee_processor.dart](../../lib/data/services/supabase_employee_processor.dart#L30-L43), `supabase/schema.sql` linhas 3263, 3292 e 3356.
- **Evidência:** formulário coleta senha; cliente passa `p_password` em `create_employee_account`; função armazena hash via bcrypt (`crypt(...gen_salt('bf',10))`). Comentário da implementação declara que conta é confirmada imediatamente e não há e-mail de confirmação; o proprietário conhece/escolhe a senha inicial.
- **Causa:** fluxo de provisionamento administrativo entrega credencial diretamente ao empregador em vez de convite/definição pelo titular.
- **Impacto:** compartilhamento/reuso, exposição da senha ao empregador e menor responsabilização individual. Não há evidência de senha em claro persistida no banco; RPC recebe sobre TLS e o hash é bcrypt.
- **Pré-requisito:** proprietário ou operador que cria a conta conhece a senha e a comunica.
- **Correção recomendada:** convite/recuperação de senha ou senha temporária de uso único com troca obrigatória antes do acesso a dados; aplicar rate limits/monitoramento server-side e nunca registrar o valor.
- **Regressão:** teste do fluxo de convite e bloqueio de acesso até troca de senha; revisar logs para garantir ausência de credencial.

### F-05 — Ficheiro de probe Dart não parseia; análise global falha

- **Severidade:** MÉDIA para qualidade/CI; **confiança:** alta.
- **Local:** arquivo não rastreado [probe_sym.dart](../../tool/probe_sym.dart#L16) e [symlink_probe.dart](../../tool/symlink_probe.dart).
- **Evidência:** `flutter analyze` produziu erros de parse/nomes indefinidos em `tool/probe_sym.dart:16` (texto PowerShell inserido em interpolação Dart) além de infos de lint nos dois probes. `dart format --output=none --set-exit-if-changed .` exit 65 e não conseguiu parsear `tool/probe_sym.dart`; informou 102 arquivos fora do format check (não alterou arquivos, por ser `--output=none`). `flutter analyze lib` passou com 0 issues.
- **Causa:** artefatos de probe do ambiente/checkout fora de `lib/` incluem sintaxe não Dart e código não formatado.
- **Impacto:** comando global `flutter analyze` falha, portanto CI que o executa falha; formatter gate global também falha. Os erros não estão em `lib/` analisada isoladamente.
- **Pré-requisito:** execução dos gates globais.
- **Correção:** identificar dono/propósito dos probes; mover comandos PowerShell para script `.ps1` ou removê-los/reescrevê-los após autorização, e formatar arquivos mantidos. Não os alterei.
- **Regressão:** `flutter analyze` e `dart format --output=none --set-exit-if-changed .` no checkout completo.

### F-06 — Web sem CSP demonstrada

- **Severidade:** BAIXA/MÉDIA condicional a web publicada; **confiança:** média (o código HTML inspecionado não apresenta CSP, mas headers do host não foram inspecionados).
- **Local:** [index.html](../../web/index.html); checklist de produção indica CSP pendente para caso de distribuição web.
- **Evidência:** HTML tem scripts inline e não contém meta CSP; configuração de headers do servidor/hosting não foi fornecida/validada.
- **Impacto:** se a versão web for publicada sem CSP em header, XSS/recursos de terceiros têm menos defesa em profundidade; sem teste de deployment não se afirma vulnerabilidade XSS.
- **Correção:** decidir se web é alvo de produção; se sim, definir CSP via headers adequados ao Flutter bootstrap/Supabase/Sentry e eliminar exceções inline onde possível; testar em staging.

### F-07 — Dados de configuração dev e segredo de credencial no ambiente local

- **Severidade:** INFORMATIVA (anon key esperada como pública) e operacional; **confiança:** alta sobre presença/tracking.
- **Local:** `env/dev.env` está rastreado; `lib/core/config/supabase_config.dart` inclui URL e anon key de desenvolvimento como defaults; `env/prod.env` existe ignorado localmente.
- **Evidência:** valores de `SUPABASE_URL` e `SUPABASE_ANON_KEY` existem em `env/dev.env` e código, valores não reproduzidos no relatório; o código comenta corretamente que anon key é pública e que RLS é fronteira de segurança. Scanner textual não encontrou padrão de `service_role`, chave privada ou token privilegiado em fontes; a varredura de histórico teve hits apenas em documentos/código de referência, sem confirmação de segredo. Não foi executado secret scanner dedicado.
- **Risco/condição:** credenciais anon/publishable são extraíveis por desenho e não devem ser tratadas como segredo; segurança exige RLS/RPC correto. `env/prod.env` presente localmente não implica vazamento. O arquivo é ignorado por regra de `env/.gitignore`.
- **Ação:** preservar anon key como pública; nunca incluir service-role/credential privilegiada em cliente; confirmar permissões/RLS e rotacionar somente se qualquer credencial privilegiada for descoberta. Executar OSV/secret scanner em CI.

### Controles observados (não constituem aprovação global)

- Supabase sessão/PKCE usa `flutter_secure_storage` no nativo; web mantém storage padrão do SDK/localStorage, risco XSS próprio da plataforma.
- Pinning nativo configurado com `SecurityContext(withTrustedRoots: false)` e WE1; cliente pinado é passado a `Supabase.initialize`. Web usa cliente browser sem certificate pinning (limitação do runtime web).
- Deep links autenticados aceitam scheme/host definidos e HTTPS callback exato. Scheme customizado continua suscetível a disputa/hijack do sistema operacional; Android App Links/assetlinks precisa de validação externa.
- Android `allowBackup=false` e data extraction rules estão configurados. Isso não resolve backup iOS.
- Schema contém RLS, helpers `SECURITY DEFINER`, `search_path=pg_catalog, public`, validação de MFA `aal2` condicionada a `tenants.mfa_enforced`, e RPC de funcionário usa bcrypt. Não foi executado SQL live nem validada a aplicação atual de `upgrade.sql` no backend.
- O Sentry registra logs/eventos explicitamente. A inspeção superficial não identificou credenciais nos logs, mas não foi auditado exaustivamente cada argumento/evento enviado; políticas de PII/retention do projeto Sentry não foram verificadas.

## D. Relatório dos testes/comandos

| Teste/comando | Resultado | Evidência/erro | Próxima ação |
|---|---|---|---|
| `flutter --version` | Aprovado com aviso ambiental | Flutter 3.47.7, Dart 3.13.5. Wrapper PowerShell avisou script ausente em `C:\src\flutter\...`; comando imprimiu versões. | Corrigir instalação/path do Flutter no host e repetir doctor/builds. |
| `flutter doctor -v` | Reprovado/ambiente incompleto | Android Studio caminho inválido; script Flutter ausente. Android SDK não configurado; ferramentas Apple inexistentes. | Instalar/configurar Android SDK/Studio e JDK compatível; usar macOS/Xcode para iOS. |
| `flutter pub get --offline --enforce-lockfile` | Aprovado na retomada anterior | Dependências estavam disponíveis em cache; saída integral não sobreviveu ao resumo da sessão. `pubspec.lock` estava modificado antes da continuação. | Conferir diff do lockfile/revisar e decidir se mudança era intencional antes de release. |
| `dart format --output=none --set-exit-if-changed .` | Reprovado | Exit 65; 102 arquivos reportados fora do format check; `tool/probe_sym.dart` não parseia. Comando não escreve arquivos. | Resolver probe inválido e formatar o conjunto de arquivos deliberadamente mantido. |
| `flutter analyze` | Reprovado | 31 issues, incluindo erros em `tool/probe_sym.dart`; restantes majoritariamente infos em probes. | Corrigir/retirar probes após identificar sua origem; repetir analyzer global. |
| `flutter analyze lib` | Aprovado | `No issues found! (ran in 10.9s)`. | Não substitui análise do repo inteiro; repetir após reparar probe. |
| `flutter test` (suíte completa) | Não aprovado / timeout | A tentativa anterior excedeu limite de 600 s sem produzir resultado final verificável. | Executar em runner limpo; capturar relatório de testes e cobertura. |
| `flutter test test/core/security test/core/network/deep_link_handler_test.dart test/core/platform/backup_exclusion_test.dart` | Aprovado | 61 testes concluídos; incluiu secure storage, AES-GCM, MFA local, deep-link validation e backup channel. | Aumentar cobertura só após correções de handler e Android manifest. |
| `flutter build web --release --dart-define-from-file=...` | Aprovado | Exit 0 na execução anterior; `build/web/index.html` existe e foi verificado como HTML. Valores de defines não expostos. | É apenas compilação; testar autenticação web/CSP e endpoints em ambiente autorizado. |
| `flutter build windows --release` | Aprovado | Exit 0; artefato `build/windows/x64/runner/Release/tareqo.exe` PE32+ x86-64, 58,880 bytes, SHA-256 `0c3645bbfb723c6f43eb29f1ee1da5b106533917559beb346b4ab75de16565a8`. Wrapper emitiu avisos; NuGet ausente/cache. | Executar smoke em Windows real, testar DB/plugins e startup. |
| `flutter build apk --debug` | Bloqueado | Exit 1: `[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.` | Instalar SDK e executar build debug/release. |
| `flutter build apk --release --flavor dev --dart-define-from-file=...` | Bloqueado | Tentativa anterior reportada com exit 1 por SDK Android ausente. | Mesmo acima; depois validar manifest merged e permissão INTERNET. |
| `flutter build appbundle --release --flavor prod --dart-define-from-file=env/prod.env` | Bloqueado | Exit 1 por Android SDK ausente antes de configurar/avaliar app build. Checkout não contém `android/key.properties` nem keystore; não há assinatura prod local. | Fornecer SDK e secrets/keystore via mecanismo seguro; não usar debug key para release público. |
| `flutter build ios --release --no-codesign` | Bloqueado por plataforma | Executado em Windows, sem Xcode/macOS; não pode produzir IPA. | Rodar no runner macOS/Xcode, instalar/resolver plugins SPM e validar assinatura separadamente. |
| `flutter pub outdated --no-transitive` / scanners OSV | Não validado | A tentativa de outdated terminou com exit 64; scanner OSV/gitleaks não instalado localmente. Workflow `security_scan.yml` usa OSV no CI, mas execução atual não consultada. | Executar scanner no CI autorizado e guardar SARIF/log; não inferir CVE-free do lockfile. |
| `git status` / inspeção de outputs | Aprovado como preservação | Muitas alterações locais preexistentes; builds geraram artefatos; sem limpeza/reset. | Manter checkout e revisar alterações em trabalho separado antes de commit/release. |

## E. Bloqueadores de build/release

### P0 — imediatos

1. **Android release sem rede:** `android/app/src/main/AndroidManifest.xml` não declara `INTERNET`; incluir permissão e confirmar manifest merged. Validação: `flutter build apk --release --flavor dev ...` + `aapt dump permissions` e teste em ambiente dev.
2. **Build Android não verificável neste host:** instalar Android SDK/command-line tools, configurar `ANDROID_HOME`/`sdk.dir`, e fornecer JDK compatível (projeto Java 17; ambiente só mostrou OpenJDK 27). Ausência do Gradle wrapper inclui `gradlew`, `.bat` e wrapper JAR; verificar política do repositório/CI antes de executar `gradle` sem wrapper. Validar com APK debug, APK release e AAB release.
3. **Release prod precisa signing material:** checkout não contém `android/key.properties` nem upload keystore; Gradle deliberadamente falha `ProdRelease` sem estes itens. Obter keystore/segredos de armazenamento autorizado (não inserir no repo/chat), configurar local ou pipeline. Validar `bundleProdRelease` e `apksigner`/`jarsigner`.
4. **Pipeline global/analyzer/format gate falha:** probe não parseável e formatação global. O estado de arquivos é compartilhado/preexistente; identificar responsável e corrigir em mudança autorizada. Validar comandos completos de analyze/format.

### P1 — prioritários antes de distribuição

- **iOS:** compilar/assinar/TestFlight apenas em macOS com Xcode, SPM/gerenciador de dependências instalado, certificado/provisioning/API keys Apple e secrets CI. O checkout local não tem Xcode, Podfile, `GoogleService-Info.plist` (Firebase não demonstrado como dependência obrigatória). O workflow que constrói IPA está configurado para runner macos-14, mas não foi executado nesta auditoria.
- **Backup iOS:** implementar e invocar a exclusão do DB/fotos ou decidir/documentar backup permitido; testar o atributo no dispositivo.
- **Suite completa:** obter resultado completo/cobertura em runner CI; os testes subset não aprovam todos os fluxos.
- **SQL/MFA:** rodar `scripts/sql_check.sh` e a verificação live somente em projeto autorizado; documentação de setembro indica que aplicação de MFA/remoção do overload ainda podia estar pendente. O estado live atual é desconhecido.

### P2 — pré-publicação

- Decidir e aplicar política de criptografia do SQLite completo (SQLCipher ou controles compensatórios/risco documentado).
- Revisar fluxo de provisionamento de funcionário para senha temporária/convite e troca obrigatória.
- Definir CSP/headers e avaliar XSS/localStorage se Web for exposto como produto.
- Obter confirmação operacional de App Links (`assetlinks.json` SHA-256), callback iOS/Universal Links e domínios de produção.
- Revalidar dep updates: `pubspec.lock` está modificado; não apagar/descartar sem aprovação do responsável.
- Confirmar metadados/identificadores, privacidade/termos, App Store/Play Console, versionamento e retenção de símbolos.

### P3 — melhorias futuras

- Auditoria formal de privacidade e retenção/PII no Sentry; teste em dispositivo comprometido e de acessibilidade; pentest autenticado de autorização multi-tenant/RPC; testes dinâmicos de rede/offline/deep links; monitoramento de supply chain/secret scanning e SBOM.

## F. Qualidade e arquitetura

- **Pontos fortes observados:** separação de camadas e injeção testável; componentes de segurança com testes focados; retry restrito a GET/HEAD; pinning não ignora falhas; segredos de sessão protegidos em plataformas nativas; RLS/RPC server-side; workflows documentados.
- **Confiabilidade do checkout:** 31 achados do analyzer global, incluindo 5 erros reais de sintaxe/nome em probe extra; analyzer `lib/` limpo. 102 arquivos incompatíveis com check de formatter no conjunto global. É um problema de higiene/gate, não prova de que a lógica de produção em `lib/` falha.
- **Persistência:** fallback do bootstrap SQLite para fontes em memória quando o SQLite falha, conforme implementação; isso pode degradar persistência silenciosamente do ponto de vista do usuário (erro vai a `debugPrint`). Validar UX/observabilidade offline para evitar impressão de que dados foram persistidos. Esta observação não foi classificada como vulnerabilidade confirmada.
- **Testes:** inventário grande e testes direcionados verdes, mas suite completa não concluiu. As declarações de contagem nos documentos históricos (381/1620 etc.) estão datadas e não substituem execução atual.
- **Performance:** não foram feitas medições; nenhuma afirmação de ganho. SQL remoto contém paginação/agregações conforme documentação, mas não foram medidas nesta execução.
- **Dependências:** lockfile alterado no checkout e outdated não completou; workflow OSV existe, mas não foi executado. Não há base para declarar dependências livres de vulnerabilidade.

## G. Plano de correção e critérios de conclusão

1. **Corrigir gate/analyzer e confirmar estado do diff** — responsável identifica os probes e arquivo lock modificado; `flutter analyze` global e `dart format --output=none --set-exit-if-changed .` terminam com exit 0 sem mudar código incidental.
2. **Corrigir rede Android** — declarar INTERNET em main manifest; manifest merged release contém permissão; APK de teste autentica/consulta dev Supabase sem cleartext.
3. **Desbloquear release Android** — ambiente SDK/JDK compatível e wrapper/Gradle verificados; build debug + prod release; assinatura validada por ferramenta Android, segredos fora do repo.
4. **Fechar iOS** — runner macOS, dependências/resolução Xcode/Swift Package, build no-code-sign seguido de signing/TestFlight apenas com credenciais configuradas; app inicia em simulador/dispositivo.
5. **Resolver backup e armazenamento** — handler/call site iOS testado; avaliação de ameaça e plano de cifragem/migração SQLite aceito; teste de migração preserva dados sintéticos e recovery.
6. **Validar backend sem tocar produção inadvertidamente** — rodar SQL suite local/Postgres; verificar RLS/RPC/MFA no staging; testar isolamento entre contas/lojas, sessão `aal1/aal2`, foreign origins quando aplicável. Live checks só após autorização e usando rotina read-only.
7. **Release checklist** — OSV/secret scan limpos ou findings triados, cobertura test suite reportada, builds por alvo, assinatura, symbols guardados, privacidade/termos e configurações externas documentadas.

## H. Checklist final de release

- [ ] `flutter analyze` global sem errors/infos não aceitos.
- [ ] `dart format --output=none --set-exit-if-changed .` aprovado.
- [ ] Suíte completa + cobertura atual executadas com saída preservada.
- [x] `lib/` passa `flutter analyze` nesta execução.
- [x] 61 testes direcionados de segurança/deep links/backup passaram.
- [x] Build web release concluído anteriormente e artefato `build/web/index.html` verificado.
- [x] Build Windows release concluído; EXE PE32+ verificado.
- [ ] APK debug/release e AAB prod construídos; Android SDK/JDK/signing pendentes.
- [ ] Permissão INTERNET está na variante release Android — **falha atual confirmada por fonte**.
- [ ] IPA/no-code-sign e TestFlight verificados em macOS/Xcode.
- [ ] SQLCipher/risco plaintext local aceito e documentado.
- [ ] Backup iOS implementado e verificado.
- [ ] Convite/troca de senha de funcionário resolvido ou risco formalmente aceito.
- [ ] RLS/MFA e migrações validadas na versão do backend que será usada.
- [ ] OSV e secret scan atuais executados; chaves privilegiadas não estão no cliente.
- [ ] Domínios/deep links/assetlinks, CSP web (se web publicado), privacy/ToS e metadados das lojas confirmados.
- [ ] Conta de release, certificados, keystore e secrets configurados por mecanismo seguro; assinatura verificada.
- [ ] Smoke tests em dispositivos/ambientes reais, sem produção destrutiva.

## I. Parecer técnico final

**Classificação: REPROVADO para distribuição Android neste estado; INCONCLUSIVO quanto à aprovação global de segurança.** O defeito de manifesto torna o modo Android release incompatível com o uso online essencial. O build Android não foi concluído porque não há SDK local, portanto não existe evidência de APK/AAB gerado. O workflow iOS não foi exercitado nesta máquina; build iOS local está bloqueado por Windows sem Xcode. Foram produzidos build web release e build Windows release, que não provam funcionamento Android/iOS nem segurança em runtime.

- **Projeto foi analisado:** sim, com escopo e profundidade documentados acima; não é auditoria linha-a-linha integral.
- **Testes executados:** sim, 61 testes focados passaram; suíte completa excedeu limite sem resultado final verificável.
- **Build concluído:** web e Windows release sim; Android APK/AAB não; iOS não executável no host.
- **Segurança validada:** parcialmente no código e testes focados; **não** validada ponta a ponta, sem scanner OSV desta execução, backend live, device testing, pentest ou verificação das configurações de produção.

**Alterações realizadas pela auditoria:** nenhum fonte/config foi modificado intencionalmente. Foram gerados artefatos nos diretórios `build/` por comandos de build. O workspace já estava sujo; preservar/revisar seus diffs antes de qualquer commit ou release.

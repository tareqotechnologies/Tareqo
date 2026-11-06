# TAREQO — Inventário de Ficheiros do Frontend

**Versão**: 1.0
**Data**: 6 de novembro de 2026
**Base**: código real em `lib/`, `assets/` e shells de plataforma
**Natureza**: documento de referência — não altera código, rotas ou regras de negócio

---

## 0. Como usar este documento

Este inventário responde a uma pergunta simples: **onde vive o frontend do TAREQO?**

- A UI Flutter está em `lib/presentation/` (ecrãs, widgets e controllers).
- A identidade visual está em `lib/core/theme/` e `lib/core/ui/`.
- Os textos localizados estão em `lib/l10n/`; a formatação de dados de UI está em `lib/core/i18n/` e nos utilitários listados em §3.
- As fontes, ícones e imagens de marca estão em `assets/`.
- Os shells nativos que arrancam a app estão em `android/`, `ios/`, `web/` e `windows/`.
- Tudo o que está fora destas pastas é backend/infraestrutura e **não** é apresentação (ver §11).

**Contagem atual:** 148 ficheiros Dart de apresentação (71 em `screens/`, 54 widgets partilhados, 23 controllers), 4 de tema, 2 de UI base, 5 de i18n, 7 de localização e 12 assets.

---

## 1. Entrada da aplicação

- `lib/main.dart` — bootstrap, `ProviderScope`, inicialização de serviços e arranque do `TareqoApp`.
- `lib/app.dart` — `MaterialApp`, tema claro/escuro, localização, `AuthGate` e `AppLockOverlay`.
- `pubspec.yaml` — dependências, declaração das fontes e assets do frontend.
- `analysis_options.yaml` — regras de análise estática que cobrem a camada de UI.

---

## 2. Sistema visual

### 2.1 Tema, tipografia e tokens

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_tokens.dart`
- `lib/core/theme/app_typography.dart`

### 2.2 UI base e interação

- `lib/core/ui/dashed_circle_painter.dart`
- `lib/core/ui/haptics.dart`

### 2.3 Contratos executáveis do design system

- `test/core/theme/typography_scale_test.dart`
- `test/presentation/widgets/typography_token_guard_test.dart`
- `test/presentation/widgets/font_weight_guard_test.dart`
- `test/core/theme/hex_guard_test.dart`
- `test/presentation/widgets/design_system_components_test.dart`

---

## 3. Internacionalização, formatação e exportação

### 3.1 Camada de tradução de UI

- `lib/core/i18n/l10n_ext.dart`
- `lib/core/i18n/domain_error_l10n.dart`
- `lib/core/i18n/payment_method_l10n.dart`
- `lib/core/i18n/addon_localization.dart`
- `lib/core/i18n/transaction_descriptions.dart`

### 3.2 Utilitários de apresentação de dados

- `lib/core/utils/formatters.dart`
- `lib/core/utils/money.dart`
- `lib/core/utils/quantity.dart`
- `lib/core/utils/receipt_text.dart`
- `lib/core/utils/scale_barcode.dart`
- `lib/core/utils/period_utils.dart`
- `lib/core/utils/app_clock.dart`
- `lib/core/utils/app_preferences.dart`
- `lib/core/utils/password_policy.dart`

### 3.3 Exportação e partilha

- `lib/core/share/receipt_sharer.dart`
- `lib/core/share/report_exporter.dart`
- `lib/core/share/document_pdf_scaffold.dart`
- `lib/core/share/pdf_accent.dart`
- `lib/core/share/invoice_pdf_exporter.dart`
- `lib/core/share/quotation_pdf_exporter.dart`
- `lib/core/share/advanced_reports_pdf_exporter.dart`

---

## 4. Estado e controllers

Ficheiros que ligam a UI aos providers/use cases (Riverpod). Não contêm regras de negócio.

- `lib/presentation/controllers/account_providers.dart`
- `lib/presentation/controllers/addon_expiry_provider.dart`
- `lib/presentation/controllers/addon_providers.dart`
- `lib/presentation/controllers/admin_message_providers.dart`
- `lib/presentation/controllers/admin_providers.dart`
- `lib/presentation/controllers/auth_providers.dart`
- `lib/presentation/controllers/custom_invoice_providers.dart`
- `lib/presentation/controllers/customers_providers.dart`
- `lib/presentation/controllers/dashboard_providers.dart`
- `lib/presentation/controllers/debts_providers.dart`
- `lib/presentation/controllers/employee_management_providers.dart`
- `lib/presentation/controllers/expiry_alerts_provider.dart`
- `lib/presentation/controllers/finance_providers.dart`
- `lib/presentation/controllers/invoice_providers.dart`
- `lib/presentation/controllers/invoice_template_providers.dart`
- `lib/presentation/controllers/notification_providers.dart`
- `lib/presentation/controllers/production_providers.dart`
- `lib/presentation/controllers/products_providers.dart`
- `lib/presentation/controllers/purchases_providers.dart`
- `lib/presentation/controllers/quotation_providers.dart`
- `lib/presentation/controllers/reports_providers.dart`
- `lib/presentation/controllers/sales_providers.dart`
- `lib/presentation/controllers/stock_transfers_provider.dart`

---

## 5. Ecrãs, sheets e widgets de módulo

### 5.1 Auth, conta e bloqueio

- `lib/presentation/screens/auth/app_lock_overlay.dart`
- `lib/presentation/screens/auth/auth_gate.dart`
- `lib/presentation/screens/auth/change_password_sheet.dart`
- `lib/presentation/screens/auth/forgot_password_sheet.dart`
- `lib/presentation/screens/auth/login_screen.dart`
- `lib/presentation/screens/auth/mfa_setup_screen.dart`
- `lib/presentation/screens/auth/mfa_verification_sheet.dart`
- `lib/presentation/screens/auth/set_new_password_screen.dart`

### 5.2 Conta e onboarding

- `lib/presentation/screens/account/security_settings_screen.dart`
- `lib/presentation/screens/account/tenant_onboarding_screen.dart`
- `lib/presentation/screens/account/tenant_pending_screen.dart`
- `lib/presentation/screens/account/tenant_rejected_screen.dart`

### 5.3 Shell e navegação

- `lib/presentation/screens/shell/app_shell.dart`
- `lib/presentation/screens/shell/menu_screen.dart`

### 5.4 Dashboard e notificações

- `lib/presentation/screens/dashboard/dashboard_screen.dart`
- `lib/presentation/screens/dashboard/notifications_screen.dart`

### 5.5 Vendas

- `lib/presentation/screens/sales/new_sale_sheet.dart`
- `lib/presentation/screens/sales/sale_detail_screen.dart`
- `lib/presentation/screens/sales/sale_receipt_share_sheet.dart`
- `lib/presentation/screens/sales/sales_screen.dart`
- `lib/presentation/screens/sales/sales_widgets.dart`

### 5.6 Financeiro

- `lib/presentation/screens/financial/add_transaction_sheet.dart`
- `lib/presentation/screens/financial/cash_closing_sheet.dart`
- `lib/presentation/screens/financial/financial_screen.dart`
- `lib/presentation/screens/financial/financial_widgets.dart`

### 5.7 Produtos

- `lib/presentation/screens/products/product_form_sheets.dart`
- `lib/presentation/screens/products/product_list_screen.dart`

### 5.8 Clientes

- `lib/presentation/screens/customers/customers_screen.dart`

### 5.9 Crédito (fiado)

- `lib/presentation/screens/credit/add_debt_sheet.dart`
- `lib/presentation/screens/credit/debts_screen.dart`

### 5.10 Compras

- `lib/presentation/screens/purchases/add_purchase_sheet.dart`
- `lib/presentation/screens/purchases/purchase_detail_sheet.dart`
- `lib/presentation/screens/purchases/purchases_screen.dart`
- `lib/presentation/screens/purchases/purchases_widgets.dart`

### 5.11 Produção

- `lib/presentation/screens/production/production_screen.dart`
- `lib/presentation/screens/production/recipe_form_sheet.dart`
- `lib/presentation/screens/production/record_production_sheet.dart`

### 5.12 Relatórios

- `lib/presentation/screens/reports/reports_screen.dart`

### 5.13 Lojas e funcionários

- `lib/presentation/screens/stores/stores_screen.dart`
- `lib/presentation/screens/stores/stores_widgets.dart`
- `lib/presentation/screens/stores/stores_widgets_details.dart`
- `lib/presentation/screens/stores/stores_widgets_settings.dart`
- `lib/presentation/screens/stores/stores_widgets_sheets.dart`
- `lib/presentation/screens/stores/stores_widgets_upgrade.dart`

### 5.14 Suporte e documentação

- `lib/presentation/screens/support/doc_reader_screen.dart`
- `lib/presentation/screens/support/support_screen.dart`

### 5.15 Add-ons

- `lib/presentation/screens/addons/addon_marketplace_screen.dart`
- `lib/presentation/screens/addons/advanced_reports_screen.dart`
- `lib/presentation/screens/addons/custom_invoice_preview.dart`
- `lib/presentation/screens/addons/custom_invoice_screen.dart`
- `lib/presentation/screens/addons/document_shared.dart`
- `lib/presentation/screens/addons/employee_management_screen.dart`
- `lib/presentation/screens/addons/payment_reconciliation_screen.dart`
- `lib/presentation/screens/addons/quotation_screen.dart`
- `lib/presentation/screens/addons/store_transfers_screen.dart`

### 5.16 Administração (super admin)

- `lib/presentation/screens/admin/admin_addon_revenue_screen.dart`
- `lib/presentation/screens/admin/admin_addons_screen.dart`
- `lib/presentation/screens/admin/admin_audit_log_screen.dart`
- `lib/presentation/screens/admin/admin_dashboard_chart_widgets.dart`
- `lib/presentation/screens/admin/admin_dashboard_feed_widgets.dart`
- `lib/presentation/screens/admin/admin_dashboard_screen.dart`
- `lib/presentation/screens/admin/admin_invoices_screen.dart`
- `lib/presentation/screens/admin/admin_messages_screen.dart`
- `lib/presentation/screens/admin/admin_plan_requests_screen.dart`
- `lib/presentation/screens/admin/admin_plans_screen.dart`
- `lib/presentation/screens/admin/admin_shell.dart`
- `lib/presentation/screens/admin/admin_tenants_screen.dart`
- `lib/presentation/screens/admin/admin_tenants_widgets.dart`
- `lib/presentation/screens/admin/admin_tenants_widgets_billing.dart`
- `lib/presentation/screens/admin/admin_tenants_widgets_sheets.dart`
- `lib/presentation/screens/admin/admin_thin_theme.dart`

---

## 6. Widgets partilhados

Componentes reutilizáveis do design system. Um ecrã novo deve preferir estes widgets antes de criar estilos locais.

- `lib/presentation/widgets/admin_thin_bridge.dart`
- `lib/presentation/widgets/app_button.dart`
- `lib/presentation/widgets/app_card.dart`
- `lib/presentation/widgets/app_menu_option.dart`
- `lib/presentation/widgets/app_page.dart`
- `lib/presentation/widgets/app_picker_field.dart`
- `lib/presentation/widgets/app_segmented_button.dart`
- `lib/presentation/widgets/app_sheet.dart`
- `lib/presentation/widgets/app_text_field.dart`
- `lib/presentation/widgets/barcode_scan_sheet.dart`
- `lib/presentation/widgets/color_palette.dart`
- `lib/presentation/widgets/confirm_dialog.dart`
- `lib/presentation/widgets/detail_row.dart`
- `lib/presentation/widgets/dialogs.dart`
- `lib/presentation/widgets/empty_state.dart`
- `lib/presentation/widgets/error_view.dart`
- `lib/presentation/widgets/fade_indexed_stack.dart`
- `lib/presentation/widgets/feed_card.dart`
- `lib/presentation/widgets/filter_dropdown.dart`
- `lib/presentation/widgets/focus_ring.dart`
- `lib/presentation/widgets/inline_error_card.dart`
- `lib/presentation/widgets/input_dialog.dart`
- `lib/presentation/widgets/kpi_card.dart`
- `lib/presentation/widgets/list_skeleton.dart`
- `lib/presentation/widgets/local_image_file_io.dart`
- `lib/presentation/widgets/local_image_file_stub.dart`
- `lib/presentation/widgets/method_badge.dart`
- `lib/presentation/widgets/metric_pill.dart`
- `lib/presentation/widgets/money_live_preview.dart`
- `lib/presentation/widgets/num_text.dart`
- `lib/presentation/widgets/payment_filter.dart`
- `lib/presentation/widgets/payment_method_picker.dart`
- `lib/presentation/widgets/period_filter.dart`
- `lib/presentation/widgets/pinned_header.dart`
- `lib/presentation/widgets/product_image.dart`
- `lib/presentation/widgets/product_type_badge.dart`
- `lib/presentation/widgets/pulse_badge.dart`
- `lib/presentation/widgets/purchase_card.dart`
- `lib/presentation/widgets/sale_card.dart`
- `lib/presentation/widgets/sale_receipt_view.dart`
- `lib/presentation/widgets/search_field.dart`
- `lib/presentation/widgets/section_header.dart`
- `lib/presentation/widgets/section_label.dart`
- `lib/presentation/widgets/semantics_composed.dart`
- `lib/presentation/widgets/sign_out_button.dart`
- `lib/presentation/widgets/skeleton.dart`
- `lib/presentation/widgets/smart_amount.dart`
- `lib/presentation/widgets/snackbar_with_undo.dart`
- `lib/presentation/widgets/staggered_list_view.dart`
- `lib/presentation/widgets/status_chip.dart`
- `lib/presentation/widgets/store_scoped_content.dart`
- `lib/presentation/widgets/store_switcher.dart`
- `lib/presentation/widgets/summary_hero.dart`
- `lib/presentation/widgets/sync_pending_banner.dart`

---

## 7. Localização

- `lib/l10n/app_pt.arb` — textos em português.
- `lib/l10n/app_en.arb` — textos em inglês.
- `lib/l10n/app_fr.arb` — textos em francês.
- `lib/l10n/generated/app_localizations.dart`
- `lib/l10n/generated/app_localizations_pt.dart`
- `lib/l10n/generated/app_localizations_en.dart`
- `lib/l10n/generated/app_localizations_fr.dart`

> Os ficheiros em `lib/l10n/generated/` são gerados. A fonte de verdade são os `.arb`.

---

## 8. Assets

### 8.1 Fontes

- `assets/fonts/Inter-Variable.ttf` — família principal da UI.
- `assets/fonts/Inter-Bold.ttf` — corte estático usado na exportação PDF.
- `assets/fonts/RobotoMono-Variable.ttf` — IDs, códigos MFA e conteúdo monoespaçado.
- `assets/fonts/OFL.txt` — licença das fontes.

### 8.2 Marca e arranque

- `assets/branding/icon_official.png`
- `assets/branding/icon_fg.png`
- `assets/branding/icon_mono.png`
- `assets/branding/icon_legacy.png`
- `assets/branding/splash_logo.png`
- `assets/branding/play_store_icon.png`
- `assets/branding/play_store_adaptive_fg.png`
- `assets/branding/play_store_feature.png`

---

## 9. Shells de plataforma

Ficheiros nativos mínimos que hospedam o motor Flutter e a identidade de arranque.

### 9.1 Android

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/tareqo/tareqo/MainActivity.kt`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`
- `android/app/src/main/res/values/colors.xml`
- `android/app/src/main/res/values-night/colors.xml`

### 9.2 iOS

- `ios/Runner/AppDelegate.swift`
- `ios/Runner/SceneDelegate.swift`
- `ios/Runner/Info.plist`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `ios/Runner/Base.lproj/Main.storyboard`

### 9.3 Web

- `web/index.html`
- `web/manifest.json`
- `web/favicon.png`

### 9.4 Windows

- `windows/runner/main.cpp`
- `windows/runner/flutter_window.cpp`
- `windows/runner/flutter_window.h`
- `windows/runner/win32_window.cpp`
- `windows/runner/win32_window.h`
- `windows/runner/Runner.rc`
- `windows/runner/runner.exe.manifest`

---

## 10. Testes de frontend

Não são código de produção, mas são os contratos que protegem esta camada.

- `test/presentation/screens/` — testes de ecrãs e fluxos.
- `test/presentation/widgets/` — testes de componentes, semântica, tipografia e movimento.
- `test/core/theme/` — escala tipográfica, cores e contraste do tema.
- `test/helpers/` — `testApp`, viewports, fixtures e spies usados pelos testes de UI.

---

## 11. Fronteira: o que não é frontend

Para evitar procurar UI no sítio errado, estas pastas são backend/infraestrutura:

- `lib/domain/` — entidades, repositórios e use cases (regras de negócio).
- `lib/data/` — datasources, repositórios concretos e serviços.
- `lib/core/database/` — SQLite.
- `lib/core/network/` — Supabase, retry, certificados e deep links.
- `lib/core/security/` — biometria, MFA, secure storage e cifra.
- `lib/core/di/` — injeção de dependências.
- `lib/core/observability/` — crash reporting.
- `lib/core/platform/` — exclusão de backup.
- `lib/core/config/` — configuração de ambiente, sabores e Supabase.
- `supabase/` — schema, RPCs, edge functions e migrações.
- `android/`, `ios/`, `web/`, `windows/` — apenas os shells listados em §9; o resto é configuração nativa/build.

---

## 12. Regra de manutenção

Ao criar um ecrã novo:

1. Adicionar o ficheiro em `lib/presentation/screens/<módulo>/`.
2. Registar a navegação em `lib/presentation/screens/shell/app_shell.dart` ou no ecrã pai.
3. Reutilizar widgets de `lib/presentation/widgets/` e tokens de `lib/core/theme/`.
4. Adicionar textos aos três `.arb` e regenerar `lib/l10n/generated/`.
5. Atualizar este inventário e `SCREEN_INVENTORY.md`.

---

*Documento gerado a partir da árvore real do repositório. Caminhos relativos à raiz do projeto.*

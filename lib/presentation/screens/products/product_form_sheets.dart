import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/i18n/domain_error_l10n.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/add_product_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_picker_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_live_preview.dart';
import '../../widgets/product_image.dart';
import '../../../core/observability/crash_reporting.dart';

/// Formulários de produto (adicionar/editar) — extraídos de
/// `product_list_screen.dart` (auditoria M5): os sheets de cadastro e
/// edição + os helpers exclusivos do formulário (picker de foto, campos,
/// rótulos de seção, switch compacto, validade).
class _ProductPhotoPicker extends StatelessWidget {
  /// Guard anti-toque-acidental (mesma abordagem do `confirm_dialog`):
  /// apagar a foto é destrutivo PERMANENTE na edição — no guardar, o
  /// storage perde o arquivo e a edição continua sem foto. Tocar sem
  /// querer na lixeira não pode perder a imagem: o `showConfirmDialog`
  /// destrutivo exige intenção explícita (§3 do design system — estado
  /// destrutivo nunca é só um tap longe do dado).
  static Future<bool> _confirmRemove(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.productsPhotoRemove,
      message: l10n.productsPhotoRemoveConfirm,
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    return confirmed == true;
  }

  const _ProductPhotoPicker({
    required this.bytes,
    required this.imagePath,
    required this.onTakePhoto,
    required this.onPickGallery,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String imagePath;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final hasImage = bytes != null || imagePath.isNotEmpty;

    final preview = bytes != null
        ? ClipRRect(
            borderRadius: AppRadius.lgAll,
            child: Image.memory(
              bytes!,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
            ),
          )
        : ProductImage(imagePath: imagePath, size: 76, iconSize: 30);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          // Preview
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: preview,
          ),
          const SizedBox(width: 16),
          // Labels + botões
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasImage ? l10n.productsPhotoTitle : l10n.productsPhotoAdd,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  hasImage
                      ? l10n.productsPhotoChangeHint
                      : l10n.productsPhotoOptionalHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PhotoActionButton(
                      icon: Icons.photo_camera_outlined,
                      tooltip: l10n.productsPhotoTake,
                      onTap: onTakePhoto,
                    ),
                    const SizedBox(width: 8),
                    _PhotoActionButton(
                      icon: Icons.photo_library_outlined,
                      tooltip: l10n.productsPhotoGallery,
                      onTap: onPickGallery,
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 8),
                      _PhotoActionButton(
                        icon: Icons.delete_outline,
                        tooltip: l10n.productsPhotoRemove,
                        onTap: () async {
                          // O diálogo bloqueia toques acidentais: sem a
                          // confirmação explícita, a foto fica intacta.
                          if (await _confirmRemove(context) &&
                              context.mounted) {
                            onRemove();
                          }
                        },
                        isDestructive: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rótulo de seção do formulário (design system ultra-clean): pequeno
/// rótulo com letter-spacing e o ícone da seção em acento — hierarquia
/// sutil que organiza os campos sem pesar visualmente.
// Estilo minimalista para campos de formulário do produto —
// labels e texto digitado menores, poluição visual reduzida.
const _kFieldStyle = TextStyle(fontSize: 12, height: 1.4);
const _kLabelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w400);
const _kFloatingLabelStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
);
const _kHintStyle = TextStyle(fontSize: 11);

/// Botão de ação minimalista para o seletor de foto.
class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDestructive
                ? scheme.error.withValues(alpha: 0.08)
                : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(
              color: isDestructive
                  ? scheme.error.withValues(alpha: 0.2)
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: IconTone.darkBackground(ModuleColors.products),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(
            icon,
            size: 12,
            color: IconTone.lightForeground(ModuleColors.products),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class AddProductSheet extends ConsumerStatefulWidget {
  const AddProductSheet({super.key});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  // W11: código de barras/PLU (5 dígitos, opcional) — usado pelas balanças
  // etiquetadoras (formato 20PPPPPWWWWW) e pelo campo do PDV.
  final _codeController = TextEditingController();

  // W11: venda por PESO (fração) + unidade de venda (kg, g, l, ml...).
  bool _vendaPorFracao = false;
  String _unitLabel = 'un';

  // Fase 1: tipo estrutural do produto. Default 'resale' — o produto
  // comum do varejo nasce vendável/comprável como sempre foi; matérias-
  // primas e produtos de produção são classificados explicitamente aqui.
  ProductType _type = ProductType.resale;

  // W11: validade opcional do produto — o lote inicial do estoque de
  // abertura nasce com ela e o dashboard alerta quando está para expirar.
  DateTime? _expiryDate;

  // Foto do produto: bytes da foto NOVA escolhida (câmera/galeria) —
  // enviada ao storage no submit; `null` = nenhuma foto nova.
  Uint8List? _imageBytes;

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Captura/pick de foto (câmera ou galeria) — comprimida na origem
  /// (1024px, JPEG 80) para uploads leves.
  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  // Interpreta o preço digitado como CENTAVOS inteiros (W4).
  int _parsePrice(String value) => Money.parse(value);

  /// Abre o seletor de data de validade do produto (lote inicial W11).
  Future<void> _pickExpiry() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: l10n.productsExpiryHelp,
    );
    if (picked == null || !mounted) return;
    setState(() => _expiryDate = picked);
  }

  /// Remove a validade definida (produto não perecível).
  void _clearExpiry() {
    setState(() => _expiryDate = null);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final purchasePriceCents = _parsePrice(_purchasePriceController.text);
    final salePriceCents = _parsePrice(_salePriceController.text);
    // W11: estoque digitado em UNIDADES (ou kg) → MILÉSIMOS.
    final stockMilli = Quantity.parse(
      _stockController.text.trim(),
      language: Formatters.currentLanguage,
    );

    // O produto pertence à loja ativa (cada loja tem seu próprio estoque).
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));

    final l10n = context.l10n;

    // Foto: sobe a imagem (se houver) ANTES de persistir o produto e
    // guarda a referência (URL/caminho) em Product.imagePath.
    //
    // A foto é OPCIONAL — se o upload falhar (ex.: storage sem permissão
    // no servidor), o produto é salvo mesmo assim com aviso, em vez de
    // bloquear o cadastro inteiro (regressão 403 RLS no live).
    var uploadedImagePath = '';
    var photoFailed = false;
    try {
      final productId = AppIds.newId('p');
      final effectiveStoreId = storeId ?? 'st1';
      final bytes = _imageBytes;
      if (bytes != null) {
        try {
          uploadedImagePath = await ref
              .read(productImageStoreProvider)
              .saveImage(
                productId: productId,
                storeId: effectiveStoreId,
                bytes: bytes,
              );
        } catch (error, stackTrace) {
          photoFailed = true;
          CrashReporting.capture(
            error,
            stackTrace,
            hint: 'Foto não enviada ao adicionar produto',
          );
        }
      }

      await ref
          .read(addProductUseCaseProvider)
          .call(
            Product(
              id: productId,
              storeId: effectiveStoreId,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              imagePath: uploadedImagePath,
              purchasePriceCents: purchasePriceCents,
              salePriceCents: salePriceCents,
              stockQuantity: stockMilli,
              code: _codeController.text.trim(),
              vendaPorFracao: _vendaPorFracao,
              unitLabel: _unitLabel,
              type: _type,
            ),
            // W11: validade opcional do lote inicial (alimenta os alertas
            // de validade do dashboard: vermelho = vencido, amarelo =
            // vence em menos de 30 dias).
            expiryDate: _expiryDate,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            photoFailed ? l10n.productsAddedNoPhoto : l10n.productsAdded,
          ),
        ),
      );
    } on InvalidPriceException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
    } catch (error, stackTrace) {
      // Upload feito mas o produto não persistiu → remove a foto órfã
      // (best-effort — nunca deixa imagem sem produto no storage).
      if (uploadedImagePath.isNotEmpty) {
        unawaited(
          ref.read(productImageStoreProvider).deleteImage(uploadedImagePath),
        );
      }
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao adicionar produto',
      );
      setState(() => _formError = l10n.productsAddError);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: SingleChildScrollView(
        padding: AppSpacing.sheetPadding,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: l10n.productsAddNew),
              // FOTO — seção própria no topo (preview + câmera/galeria).
              const SizedBox(height: 16),
              _ProductPhotoPicker(
                bytes: _imageBytes,
                imagePath: '',
                onTakePhoto: () => _pickPhoto(ImageSource.camera),
                onPickGallery: () => _pickPhoto(ImageSource.gallery),
                onRemove: () => setState(() => _imageBytes = null),
              ),
              const SizedBox(height: 24),
              // INFORMAÇÕES — identidade do produto.
              _SectionLabel(
                icon: Icons.inventory_2_outlined,
                title: l10n.productsSectionInfo,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                label: l10n.loginNameLabel,
                prefixIcon: Icons.inventory_2_outlined,
                style: _kFieldStyle,
                labelStyle: _kLabelStyle,
                floatingLabelStyle: _kFloatingLabelStyle,
                decorationHintStyle: _kHintStyle,
                isDense: true,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.productsNameError
                    : null,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                label: l10n.productsDescriptionLabel,
                prefixIcon: Icons.notes_outlined,
                style: _kFieldStyle,
                labelStyle: _kLabelStyle,
                floatingLabelStyle: _kFloatingLabelStyle,
                decorationHintStyle: _kHintStyle,
                isDense: true,
              ),
              const SizedBox(height: 8),
              // W11: código de barras/PLU — usado pelas balanças
              // etiquetadoras (20PPPPPWWWWW) e pelo campo do PDV.
              AppTextField(
                controller: _codeController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                maxLength: 5,
                label: l10n.productsCodeLabel,
                helperText: l10n.productsCodeHint,
                prefixIcon: Icons.qr_code_2_outlined,
                style: _kFieldStyle,
                labelStyle: _kLabelStyle,
                floatingLabelStyle: _kFloatingLabelStyle,
                decorationHintStyle: _kHintStyle,
                // Helper longo + counter (0/5): fonte menor para não truncar.
                helperStyle: const TextStyle(fontSize: 10),
                isDense: true,
                validator: (value) {
                  final digits = value?.trim() ?? '';
                  if (digits.isNotEmpty &&
                      !RegExp(r'^\d{1,5}$').hasMatch(digits)) {
                    return l10n.productsCodeError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Fase 1: tipo estrutural do produto (matéria-prima,
              // revenda, produzido, composto, embalagem). Define o papel
              // na produção/receitas das fases seguintes — o default
              // 'revenda' mantém o comportamento do varejo.
              AppPickerField<ProductType>(
                value: _type,
                label: l10n.productsTypeLabel,
                prefixIcon: Icons.category_outlined,
                items: [
                  for (final type in ProductType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) =>
                    setState(() => _type = value ?? ProductType.resale),
              ),
              const SizedBox(height: 16),
              // PREÇOS — compra e venda lado a lado.
              _SectionLabel(
                icon: Icons.payments_outlined,
                title: l10n.productsSectionPricing,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      label: l10n.productsPurchasePrice,
                      style: _kFieldStyle,
                      labelStyle: _kLabelStyle,
                      floatingLabelStyle: _kFloatingLabelStyle,
                      decorationHintStyle: _kHintStyle,
                      isDense: true,
                      validator: (value) => _parsePrice(value ?? '') <= 0
                          ? l10n.productsPurchasePriceError
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _salePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      label: l10n.productsSalePrice,
                      style: _kFieldStyle,
                      labelStyle: _kLabelStyle,
                      floatingLabelStyle: _kFloatingLabelStyle,
                      decorationHintStyle: _kHintStyle,
                      isDense: true,
                      validator: (value) => _parsePrice(value ?? '') <= 0
                          ? l10n.productsSalePriceError
                          : null,
                    ),
                  ),
                ],
              ),
              // A2: preview ao vivo dos preços digitados (compra e venda) —
              // alinhado com os campos acima, mostrando "= R$ 1.390,00" ANTES
              // de salvar (evita registrar 100× o pretendido).
              Row(
                children: [
                  Expanded(
                    child: MoneyLivePreview(
                      controller: _purchasePriceController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MoneyLivePreview(controller: _salePriceController),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // ESTOQUE — quantidade + validade + venda por peso.
              _SectionLabel(
                icon: Icons.warehouse_outlined,
                title: l10n.productsSectionStock,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _stockController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                label: l10n.productsStockQuantity,
                helperText: _vendaPorFracao
                    ? l10n.productsStockWeightHint
                    : null,
                prefixIcon: Icons.warehouse_outlined,
                style: _kFieldStyle,
                labelStyle: _kLabelStyle,
                floatingLabelStyle: _kFloatingLabelStyle,
                decorationHintStyle: _kHintStyle,
                isDense: true,
                validator: (value) {
                  // W11: aceita decimais (ex.: 1,75) — convertido para
                  // milésimos no submit; rejeita texto/números negativos.
                  final quantity = Quantity.parse(
                    value?.trim() ?? '',
                    language: Formatters.currentLanguage,
                  );
                  if (quantity < 0 ||
                      (value != null &&
                          value.trim().isNotEmpty &&
                          quantity == 0)) {
                    return l10n.productsStockError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              // W11: validade opcional — o lote inicial do estoque de
              // abertura nasce com ela; o dashboard alerta (vermelho =
              // vencido; amarelo = vence em < 30 dias) quando expira.
              // Seletor MINIMALISTA: um único campo no padrão dos demais
              // inputs (borda sutil + ícone), sem botão largo separado.
              _ExpiryField(
                expiryDate: _expiryDate,
                onPick: _pickExpiry,
                onClear: _clearExpiry,
              ),
              const SizedBox(height: 4),
              // W11: venda por PESO (fração) — o PDV passa a aceitar
              // quantidades decimais e o código de barras de balança.
              // Material explícito: o SwitchListTile pinta o fundo e o ink no
              // Material ancestral; dentro do Container colorido do app_sheet
              // (DecoratedBox) o Flutter emite a assertion "ListTile
              // background color or ink splashes may be invisible" (mesmo
              // padrão já usado no add_transaction_sheet).
              _CompactSwitch(
                label: l10n.productsWeighLabel,
                subtitle: l10n.productsWeighHint,
                value: _vendaPorFracao,
                onChanged: (value) => setState(() {
                  _vendaPorFracao = value;
                  _unitLabel = value ? 'kg' : 'un';
                }),
              ),
              if (_vendaPorFracao) ...[
                AppPickerField<String>(
                  value: _unitLabel,
                  label: l10n.productsUnitLabel,
                  prefixIcon: Icons.scale_outlined,
                  items: [
                    for (final unit in const ['kg', 'g', 'l', 'ml'])
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: (value) =>
                      setState(() => _unitLabel = value ?? 'kg'),
                ),
              ],
              if (_formError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _formError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppButton.primary(
                label: l10n.productsAddSubmit,
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet de EDIÇÃO de produto — dono/gerente altera nome,
/// descrição, código/PLU, preços, venda por peso, estoque (AJUSTE MANUAL:
/// cria/consome lotes FIFO) e o status ativo (desativar tira o produto do
/// PDV e das compras; o estoque é preservado para a reativação).
class EditProductSheet extends ConsumerStatefulWidget {
  const EditProductSheet({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends ConsumerState<EditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _codeController;

  late bool _vendaPorFracao;
  late String _unitLabel;
  late bool _isActive;
  // Fase 1: tipo estrutural (pré-preenchido com o tipo atual do produto).
  late ProductType _type = widget.product.type;

  // Foto do produto: bytes da foto NOVA escolhida, referência ATUAL
  // persistida e referência de uma foto REMOVIDA (apagada no submit).
  Uint8List? _imageBytes;
  late String _imagePath = widget.product.imagePath;
  String _removedImagePath = '';

  bool _isSubmitting = false;
  String? _formError;

  Product get _product => widget.product;

  @override
  void initState() {
    super.initState();
    // Pré-preenche com os valores atuais (a edição nunca parte em branco).
    _nameController = TextEditingController(text: _product.name);
    _descriptionController = TextEditingController(text: _product.description);
    // Pré-preenche com o valor SEM símbolo ("13.90") — o Money.parse
    // aceita vírgula ou ponto, então o texto volta ao banco como centavos.
    _purchasePriceController = TextEditingController(
      text: Money.toReais(_product.purchasePriceCents).toStringAsFixed(2),
    );
    _salePriceController = TextEditingController(
      text: Money.toReais(_product.salePriceCents).toStringAsFixed(2),
    );
    _stockController = TextEditingController(
      text: Quantity.format(
        _product.stockQuantity,
        unitLabel: _product.vendaPorFracao ? _product.unitLabel : null,
        language: Formatters.currentLanguage,
      ).split(' ').first,
    );
    _codeController = TextEditingController(text: _product.code);
    _vendaPorFracao = _product.vendaPorFracao;
    _unitLabel = _product.vendaPorFracao ? _product.unitLabel : 'un';
    _isActive = _product.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // Interpreta o preço digitado como CENTAVOS inteiros (W4).
  int _parsePrice(String value) => Money.parse(value);

  /// Captura/pick de foto (câmera ou galeria) — comprimida na origem
  /// (1024px, JPEG 80) para uploads leves.
  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  /// Remove a foto: anota a referência atual para apagar no submit e
  /// limpa preview/estado.
  void _removePhoto() {
    setState(() {
      _removedImagePath = _imagePath;
      _imagePath = '';
      _imageBytes = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final l10n = context.l10n;

    // Foto: sobe a imagem NOVA (se houver) ANTES de persistir; apaga a
    // imagem REMOVIDA (best-effort). O objeto/arquivo tem o MESMO caminho
    // por produto, então substituir não deixa órfão.
    //
    // A foto é OPCIONAL — se o upload falhar (ex.: storage sem permissão
    // no servidor), o produto é salvo mesmo assim com aviso, em vez de
    // bloquear a edição inteira (regressão 403 RLS no live).
    var uploadedImagePath = '';
    var photoFailed = false;
    try {
      final store = ref.read(productImageStoreProvider);
      final bytes = _imageBytes;
      final String imagePath;
      if (bytes != null) {
        try {
          uploadedImagePath = await store.saveImage(
            productId: _product.id,
            storeId: _product.storeId,
            bytes: bytes,
          );
        } catch (error, stackTrace) {
          photoFailed = true;
          CrashReporting.capture(
            error,
            stackTrace,
            hint: 'Foto não enviada ao editar produto',
          );
        }
        if (uploadedImagePath.isNotEmpty &&
            _removedImagePath.isNotEmpty &&
            _removedImagePath != uploadedImagePath) {
          unawaited(store.deleteImage(_removedImagePath));
        }
        // Falhou o upload → mantém a foto ATUAL (não apaga a existente);
        // a edição segue sem foto nova, com aviso no snackbar.
        imagePath = photoFailed && _imagePath.isNotEmpty
            ? _imagePath
            : uploadedImagePath;
      } else if (_removedImagePath.isNotEmpty) {
        unawaited(store.deleteImage(_removedImagePath));
        imagePath = '';
      } else {
        imagePath = _imagePath;
      }

      final useCase = ref.read(updateProductUseCaseProvider);
      final updated = _product.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imagePath: imagePath,
        purchasePriceCents: _parsePrice(_purchasePriceController.text),
        salePriceCents: _parsePrice(_salePriceController.text),
        code: _codeController.text.trim(),
        vendaPorFracao: _vendaPorFracao,
        unitLabel: _unitLabel,
        isActive: _isActive,
        type: _type,
      );

      // 1) Campos do catálogo (nome/preços/código/fração/status ativo) —
      // o estoque NÃO entra neste update (invariante stock = Σ lotes).
      await useCase.updateDetails(updated);

      // 2) Ajuste MANUAL do estoque (apenas se o valor mudou): define a
      // quantidade exata criando/consumindo lotes FIFO na mesma transação.
      final stockMilli = Quantity.parse(
        _stockController.text.trim(),
        language: Formatters.currentLanguage,
      );
      if (stockMilli != _product.stockQuantity) {
        await useCase.adjustStock(
          _product.id,
          stockMilli,
          storeId: _product.storeId,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            photoFailed
                ? l10n.productsEditSavedNoPhoto
                : l10n.productsEditSaved,
          ),
        ),
      );
    } on InvalidPriceException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
    } catch (error, stackTrace) {
      // Upload feito mas o produto não persistiu → remove a foto órfã
      // (best-effort — nunca deixa imagem sem produto no storage).
      if (uploadedImagePath.isNotEmpty) {
        unawaited(
          ref.read(productImageStoreProvider).deleteImage(uploadedImagePath),
        );
      }
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao editar produto');
      setState(() => _formError = l10n.productsEditError);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: AppSpacing.sheetPadding,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: l10n.productsEditTitle),
              // FOTO — seção própria no topo (preview + câmera/galeria).
              const SizedBox(height: 16),
              _ProductPhotoPicker(
                bytes: _imageBytes,
                imagePath: _imagePath,
                onTakePhoto: () => _pickPhoto(ImageSource.camera),
                onPickGallery: () => _pickPhoto(ImageSource.gallery),
                onRemove: _removePhoto,
              ),
              const SizedBox(height: 24),
              // INFORMAÇÕES — identidade do produto.
              _SectionLabel(
                icon: Icons.inventory_2_outlined,
                title: l10n.productsSectionInfo,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                label: l10n.loginNameLabel,
                prefixIcon: Icons.inventory_2_outlined,
                style: _kFieldStyle,
                labelStyle: _kLabelStyle,
                floatingLabelStyle: _kFloatingLabelStyle,
                decorationHintStyle: _kHintStyle,
                isDense: true,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.productsNameError
                    : null,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                label: l10n.productsDescriptionLabel,
                prefixIcon: Icons.notes_outlined,
                style: _kFieldStyle,
                labelStyle: _kLabelStyle,
                floatingLabelStyle: _kFloatingLabelStyle,
                decorationHintStyle: _kHintStyle,
                isDense: true,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _codeController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                maxLength: 5,
                label: l10n.productsCodeLabel,
                helperText: l10n.productsCodeHint,
                prefixIcon: Icons.qr_code_2_outlined,
                style: _kFieldStyle,
                labelStyle: _kLabelStyle,
                floatingLabelStyle: _kFloatingLabelStyle,
                decorationHintStyle: _kHintStyle,
                // Helper longo + counter (0/5): fonte menor para não truncar.
                helperStyle: const TextStyle(fontSize: 10),
                isDense: true,
                validator: (value) {
                  final digits = value?.trim() ?? '';
                  if (digits.isNotEmpty &&
                      !RegExp(r'^\d{1,5}$').hasMatch(digits)) {
                    return l10n.productsCodeError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Fase 1: tipo estrutural do produto — pré-preenchido com o
              // tipo atual; reclassificar é permitido ao dono/gerente.
              AppPickerField<ProductType>(
                value: _type,
                label: l10n.productsTypeLabel,
                prefixIcon: Icons.category_outlined,
                items: [
                  for (final type in ProductType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) =>
                    setState(() => _type = value ?? ProductType.resale),
              ),
              const SizedBox(height: 16),
              // PREÇOS — compra e venda lado a lado.
              _SectionLabel(
                icon: Icons.payments_outlined,
                title: l10n.productsSectionPricing,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      label: l10n.productsPurchasePrice,
                      style: _kFieldStyle,
                      labelStyle: _kLabelStyle,
                      floatingLabelStyle: _kFloatingLabelStyle,
                      decorationHintStyle: _kHintStyle,
                      isDense: true,
                      validator: (value) => _parsePrice(value ?? '') <= 0
                          ? l10n.productsPurchasePriceError
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _salePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      label: l10n.productsSalePrice,
                      style: _kFieldStyle,
                      labelStyle: _kLabelStyle,
                      floatingLabelStyle: _kFloatingLabelStyle,
                      decorationHintStyle: _kHintStyle,
                      isDense: true,
                      validator: (value) => _parsePrice(value ?? '') <= 0
                          ? l10n.productsSalePriceError
                          : null,
                    ),
                  ),
                ],
              ),
              // A2: preview ao vivo dos preços digitados (compra e venda).
              Row(
                children: [
                  Expanded(
                    child: MoneyLivePreview(
                      controller: _purchasePriceController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MoneyLivePreview(controller: _salePriceController),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ESTOQUE — quantidade exata + venda por peso (FIFO).
              _SectionLabel(
                icon: Icons.warehouse_outlined,
                title: l10n.productsSectionStock,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _stockController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                label: l10n.productsStockQuantity,
                helperText: _vendaPorFracao
                    ? l10n.productsStockWeightHint
                    : l10n.productsStockAdjustHint,
                prefixIcon: Icons.warehouse_outlined,
                style: _kFieldStyle,
                labelStyle: _kLabelStyle,
                floatingLabelStyle: _kFloatingLabelStyle,
                decorationHintStyle: _kHintStyle,
                isDense: true,
                validator: (value) {
                  // Edição: aceita ZERO explícito (zerar o estoque é um
                  // ajuste legítimo — ex.: quebra total). Vazio = 0.
                  // Rejeita texto não numérico e negativos.
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final normalized = text
                      .replaceAll(' ', '')
                      .replaceAll(',', '.');
                  final parsed = double.tryParse(normalized);
                  if (parsed == null || parsed < 0) {
                    return l10n.productsStockError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              _CompactSwitch(
                label: l10n.productsWeighLabel,
                subtitle: l10n.productsWeighHint,
                value: _vendaPorFracao,
                onChanged: (value) => setState(() {
                  _vendaPorFracao = value;
                  _unitLabel = value ? 'kg' : 'un';
                }),
              ),
              if (_vendaPorFracao) ...[
                AppPickerField<String>(
                  value: _unitLabel,
                  label: l10n.productsUnitLabel,
                  prefixIcon: Icons.scale_outlined,
                  items: [
                    for (final unit in const ['kg', 'g', 'l', 'ml'])
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: (value) =>
                      setState(() => _unitLabel = value ?? 'kg'),
                ),
              ],
              const SizedBox(height: 24),
              // STATUS — ativar/desativar (inativo some do PDV e das
              // compras; o estoque é preservado — a reativação devolve a
              // venda).
              _SectionLabel(
                icon: Icons.toggle_on_outlined,
                title: l10n.productsSectionStatus,
              ),
              const SizedBox(height: 12),
              _CompactSwitch(
                label: l10n.productsActiveLabel,
                subtitle: l10n.productsActiveHint,
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _formError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppButton.primary(
                label: l10n.productsEditSubmit,
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seletor de validade MINIMALISTA (W11) — um único campo compacto no
/// padrão dos demais inputs do formulário (borda sutil + ícone de calendário),
/// em vez do botão largo com texto grande e botão de limpar solto.
///
/// Vazio: mostra apenas "Definir validade" (toque abre o date picker). Com
/// data: mostra "Validade · dd/mm/aaaa" em destaque + um X discreto à direita
/// (tooltip "Remover validade") para limpar — os mesmos rótulos/tooltips de
/// antes, só que integrados num único campo.
class _ExpiryField extends StatelessWidget {
  const _ExpiryField({
    required this.expiryDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? expiryDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final hasDate = expiryDate != null;

    // Semantics: o campo inteiro é um botão (abre o date picker) — leitores
    // de tela anunciam a ação, não só o texto visível (como no X de limpar,
    // que já tem tooltip).
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          // minHeight (e não altura fixa): com escala de texto alta a data
          // 'Validade · dd/mm/aaaa' quebra em 2 linhas sem cortar o texto.
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.event_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasDate
                      ? '${l10n.productsExpiryLabel} · '
                            '${Formatters.date(expiryDate!)}'
                      : l10n.productsExpiryAdd,
                  // Quebra em até 2 linhas — a data nunca é cortada.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasDate ? scheme.onSurface : scheme.onSurfaceVariant,
                    fontWeight: hasDate ? FontWeight.w600 : null,
                  ),
                ),
              ),
              if (hasDate) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: l10n.productsExpiryClear,
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onClear,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

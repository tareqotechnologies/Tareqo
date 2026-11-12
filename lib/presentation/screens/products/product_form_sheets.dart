import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/i18n/domain_error_l10n.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
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
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/barcode_scan_sheet.dart';
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
      context: context,
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final hasImage = bytes != null || imagePath.isNotEmpty;

    final preview = bytes != null
        ? ClipRRect(
            borderRadius: AppRadius.mdAll,
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
        // Mesma superfície de grupo do [SheetSection] (o formulário inteiro
        // fala a mesma língua).
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: AppRadius.lgAll,
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
          const SizedBox(width: AppSpacing.md),
          // Labels + botões
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasImage ? l10n.productsPhotoTitle : l10n.productsPhotoAdd,
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  hasImage
                      ? l10n.productsPhotoChangeHint
                      : l10n.productsPhotoOptionalHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PhotoActionButton(
                      icon: Icons.photo_camera_outlined,
                      tooltip: l10n.productsPhotoTake,
                      onTap: onTakePhoto,
                      isPrimary: true,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _PhotoActionButton(
                      icon: Icons.photo_library_outlined,
                      tooltip: l10n.productsPhotoGallery,
                      onTap: onPickGallery,
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: AppSpacing.xs),
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

/// Botão de ação minimalista para o seletor de foto.
class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDestructive = false,
    this.isPrimary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  /// Ação principal (câmera): preenchimento tinta com glifo Void — mesma
  /// regra de contraste das demais superfícies cheias da marca (6.2:1).
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isPrimary
        ? scheme.onPrimary
        : isDestructive
        ? scheme.error
        : scheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Alvo de toque do design system (48dp) — a fileira de ações da
          // foto não pode ficar abaixo do mínimo de acessibilidade.
          width: AppSizes.touchTarget,
          height: AppSizes.touchTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isPrimary
                ? scheme.primary
                : isDestructive
                ? scheme.error.withValues(alpha: 0.08)
                : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isPrimary
                  ? scheme.primary
                  : isDestructive
                  ? scheme.error.withValues(alpha: 0.2)
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(icon, size: AppSizes.iconMd, color: color),
        ),
      ),
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.embedded = false,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// `true` quando o switch já está dentro de uma [SheetSection] — evita
  /// caixa dentro de caixa (a superfície do grupo já é o fundo).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.micro),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );

    if (embedded) return content;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: content,
    );
  }
}

/// Lê a foto escolhida (câmera ou galeria) — já comprimida na origem
/// (1024px, JPEG 80) para uploads leves. `null` = o usuário cancelou.
///
/// Auxiliar COMUM a Add/Edit — antes duplicado em ambos os sheets.
Future<Uint8List?> _pickPhotoBytes(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 80,
  );
  if (picked == null) return null;
  return picked.readAsBytes();
}

/// Seção ESTOQUE (quantidade, validade opcional e venda por peso) — comum
/// a novo/editar produto. A validade só existe na criação (lote inicial).
class _StockSection extends StatelessWidget {
  const _StockSection({
    required this.stockController,
    required this.stockHelperText,
    required this.stockValidator,
    required this.vendaPorFracao,
    required this.unitLabel,
    required this.onWeightChanged,
    required this.onUnitChanged,
    this.expiryField,
  });

  final TextEditingController stockController;
  final String? stockHelperText;
  final FormFieldValidator<String> stockValidator;
  final bool vendaPorFracao;
  final String unitLabel;
  final ValueChanged<bool> onWeightChanged;
  final ValueChanged<String?> onUnitChanged;
  final Widget? expiryField;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SheetSection(
      icon: Icons.warehouse_outlined,
      title: l10n.productsSectionStock,
      children: [
        AppTextField(
          controller: stockController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          label: l10n.productsStockQuantity,
          helperText: stockHelperText,
          prefixIcon: Icons.warehouse_outlined,
          validator: stockValidator,
        ),
        if (expiryField != null) ...[
          const SizedBox(height: AppSpacing.xs),
          expiryField!,
        ],
        const SizedBox(height: AppSpacing.sm),
        ProductWeightFields(
          vendaPorFracao: vendaPorFracao,
          unitLabel: unitLabel,
          onWeightChanged: onWeightChanged,
          onUnitChanged: onUnitChanged,
        ),
      ],
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
  final _barcodeController = TextEditingController();

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
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final bytes = await _pickPhotoBytes(source);
    if (bytes == null || !mounted) return;
    setState(() => _imageBytes = bytes);
  }

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

    final purchasePriceCents = Money.parse(_purchasePriceController.text);
    final salePriceCents = Money.parse(_salePriceController.text);
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
    final l10n = context.l10n;

    return SheetForm(
      formKey: _formKey,
      title: l10n.productsAddNew,
      maxHeightFactor: 0.88,
      error: _formError,
      actionLabel: l10n.productsAddSubmit,
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      children: [
        // FOTO — preview + câmera/galeria no topo (mesma superfície de grupo).
        _ProductPhotoPicker(
          bytes: _imageBytes,
          imagePath: '',
          onTakePhoto: () => _pickPhoto(ImageSource.camera),
          onPickGallery: () => _pickPhoto(ImageSource.gallery),
          onRemove: () => setState(() => _imageBytes = null),
        ),
        const SizedBox(height: AppSpacing.md),
        ProductIdentitySection(
          nameController: _nameController,
          descriptionController: _descriptionController,
          codeController: _codeController,
          barcodeController: _barcodeController,
          type: _type,
          onTypeChanged: (value) =>
              setState(() => _type = value ?? ProductType.resale),
          onScanBarcode: () async {
            final code = await showBarcodeScanner(context);
            if (code != null && code.isNotEmpty) {
              final digits = code.replaceAll(' ', '').trim();
              _barcodeController.text = digits.isNotEmpty
                  ? digits
                  : code.trim();
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ProductPricingFields(
          purchaseController: _purchasePriceController,
          saleController: _salePriceController,
        ),
        const SizedBox(height: AppSpacing.md),
        _StockSection(
          stockController: _stockController,
          stockHelperText: _vendaPorFracao
              ? l10n.productsStockWeightHint
              : null,
          stockValidator: (value) {
            // W11: aceita decimais (ex.: 1,75) — convertido para
            // milésimos no submit; rejeita texto/números negativos.
            final quantity = Quantity.parse(
              value?.trim() ?? '',
              language: Formatters.currentLanguage,
            );
            if (quantity < 0 ||
                (value != null && value.trim().isNotEmpty && quantity == 0)) {
              return l10n.productsStockError;
            }
            return null;
          },
          vendaPorFracao: _vendaPorFracao,
          unitLabel: _unitLabel,
          onWeightChanged: (value) => setState(() {
            _vendaPorFracao = value;
            _unitLabel = value ? 'kg' : 'un';
          }),
          onUnitChanged: (value) => setState(() => _unitLabel = value ?? 'kg'),
          // W11: validade opcional do lote inicial — alimenta os alertas do
          // dashboard (vencido / vence em menos de 30 dias).
          expiryField: _ExpiryField(
            expiryDate: _expiryDate,
            onPick: _pickExpiry,
            onClear: _clearExpiry,
          ),
        ),
      ],
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
  late final TextEditingController _barcodeController;

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
    _barcodeController = TextEditingController(text: _product.barcode);
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
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final bytes = await _pickPhotoBytes(source);
    if (bytes == null || !mounted) return;
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
        purchasePriceCents: Money.parse(_purchasePriceController.text),
        salePriceCents: Money.parse(_salePriceController.text),
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
    final l10n = context.l10n;

    return SheetForm(
      formKey: _formKey,
      title: l10n.productsEditTitle,
      maxHeightFactor: 0.9,
      error: _formError,
      actionLabel: l10n.productsEditSubmit,
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      children: [
        // FOTO — preview + câmera/galeria no topo (mesma superfície de grupo).
        _ProductPhotoPicker(
          bytes: _imageBytes,
          imagePath: _imagePath,
          onTakePhoto: () => _pickPhoto(ImageSource.camera),
          onPickGallery: () => _pickPhoto(ImageSource.gallery),
          onRemove: _removePhoto,
        ),
        const SizedBox(height: AppSpacing.md),
        ProductIdentitySection(
          nameController: _nameController,
          descriptionController: _descriptionController,
          codeController: _codeController,
          barcodeController: _barcodeController,
          type: _type,
          onTypeChanged: (value) =>
              setState(() => _type = value ?? ProductType.resale),
          onScanBarcode: () async {
            final code = await showBarcodeScanner(context);
            if (code != null && code.isNotEmpty) {
              final digits = code.replaceAll(' ', '').trim();
              _barcodeController.text = digits.isNotEmpty
                  ? digits
                  : code.trim();
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ProductPricingFields(
          purchaseController: _purchasePriceController,
          saleController: _salePriceController,
        ),
        const SizedBox(height: AppSpacing.md),
        _StockSection(
          stockController: _stockController,
          stockHelperText: _vendaPorFracao
              ? l10n.productsStockWeightHint
              : l10n.productsStockAdjustHint,
          stockValidator: (value) {
            // Edição: aceita ZERO explícito (zerar o estoque é um ajuste
            // legítimo — ex.: quebra total). Vazio = 0. Rejeita texto
            // não numérico e negativos.
            final text = value?.trim() ?? '';
            if (text.isEmpty) return null;
            final normalized = text.replaceAll(' ', '').replaceAll(',', '.');
            final parsed = double.tryParse(normalized);
            if (parsed == null || parsed < 0) {
              return l10n.productsStockError;
            }
            return null;
          },
          vendaPorFracao: _vendaPorFracao,
          unitLabel: _unitLabel,
          onWeightChanged: (value) => setState(() {
            _vendaPorFracao = value;
            _unitLabel = value ? 'kg' : 'un';
          }),
          onUnitChanged: (value) => setState(() => _unitLabel = value ?? 'kg'),
        ),
        const SizedBox(height: AppSpacing.md),
        // STATUS — inativo some do PDV e das compras; o estoque é
        // preservado e a reativação devolve a venda.
        SheetSection(
          icon: Icons.toggle_on_outlined,
          title: l10n.productsSectionStatus,
          children: [
            _CompactSwitch(
              label: l10n.productsActiveLabel,
              subtitle: l10n.productsActiveHint,
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              embedded: true,
            ),
          ],
        ),
      ],
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
    // Mesma moldura/fill do AppTextField — o seletor de validade lê como
    // parte do formulário, não como um botão à parte.
    final fieldBorder = theme.brightness == Brightness.light
        ? AppColors.grayMid
        : AppColors.darkBorder;

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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor ?? scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: fieldBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.event_outlined,
                size: AppSizes.iconMd,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hasDate
                      ? '${l10n.productsExpiryLabel} · '
                            '${Formatters.date(expiryDate!)}'
                      : l10n.productsExpiryAdd,
                  // Quebra em até 2 linhas — a data nunca é cortada.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Vazio = convite em corpo; preenchido = valor em
                  // labelLarge (14/500) — o peso não sai da escala.
                  style:
                      (hasDate
                              ? AppTypography.labelLarge
                              : AppTypography.bodyMedium)
                          .copyWith(
                            color: hasDate
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                ),
              ),
              if (hasDate) ...[
                const SizedBox(width: AppSpacing.xxs),
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

/// Campos de IDENTIDADE do produto (nome, descrição, código/PLU e tipo
/// estrutural) — widget COMUM aos sheets de adicionar/editar produto.
/// Antes: blocos duplicados (~100 linhas) nos dois builds, que já haviam
/// divergido em comentários. Esta é a fonte única.
class ProductIdentitySection extends StatelessWidget {
  const ProductIdentitySection({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.codeController,
    required this.barcodeController,
    required this.type,
    required this.onTypeChanged,
    this.onScanBarcode,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController codeController;
  final TextEditingController barcodeController;
  final ProductType type;
  final ValueChanged<ProductType?> onTypeChanged;

  /// Captura por câmera (QR/barcode) — abre o leitor e preenche o
  /// campo de barcode; `null` = sem botão de scan.
  final VoidCallback? onScanBarcode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetSection(
      icon: Icons.inventory_2_outlined,
      title: l10n.productsSectionInfo,
      children: [
        AppTextField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          label: l10n.loginNameLabel,
          prefixIcon: Icons.inventory_2_outlined,
          // Validação: campo obrigatório; erro aparece abaixo do campo
          validator: (value) => (value == null || value.trim().isEmpty)
              ? l10n.productsNameError
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: descriptionController,
          textInputAction: TextInputAction.next,
          label: l10n.productsDescriptionLabel,
          prefixIcon: Icons.notes_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        // W11: código de barras/PLU — usado pelas balanças etiquetadoras
        // (20PPPPPWWWWW) e pelo campo de código de barras do PDV.
        AppTextField(
          controller: codeController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          maxLength: 5,
          label: l10n.productsCodeLabel,
          helperText: l10n.productsCodeHint,
          prefixIcon: Icons.qr_code_2_outlined,
          // Validação: apenas 1-5 dígitos; erro abaixo do campo
          validator: (value) {
            final digits = value?.trim() ?? '';
            if (digits.isNotEmpty && !RegExp(r'^\d{1,5}$').hasMatch(digits)) {
              return l10n.productsCodeError;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        // Código de barras convencional (EAN-13, EAN-8, UPC-A, UPC-E,
        // Code 128) — opcional e independente do PLU.
        AppTextField(
          controller: barcodeController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.text,
          maxLength: 13,
          label: l10n.productsBarcodeLabel,
          helperText: l10n.productsBarcodeHint,
          prefixIcon: Icons.qr_code,
          suffixIcon: onScanBarcode == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.center_focus_strong),
                  tooltip: l10n.productsBarcodeLabel,
                  onPressed: onScanBarcode,
                ),
          // Validação: aceita EAN-13 (13 dígitos), EAN-8 (8 dígitos),
          // UPC-A (12 dígitos), UPC-E (8 dígitos) e Code 128 (variável).
          // Zeros à esquerda são preservados tratando como texto.
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isNotEmpty) {
              final cleaned = text.replaceAll(' ', '');
              if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
                return l10n.productsBarcodeError;
              }
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        // Fase 1: tipo estrutural do produto (matéria-prima, revenda,
        // produzido, composto, embalagem).
        AppPickerField<ProductType>(
          value: type,
          label: l10n.productsTypeLabel,
          prefixIcon: Icons.category_outlined,
          items: [
            for (final t in ProductType.values)
              DropdownMenuItem(value: t, child: Text(t.label)),
          ],
          onChanged: onTypeChanged,
        ),
      ],
    );
  }
}

/// Par de PREÇOS (compra/venda) + preview ao vivo (A2) — widget COMUM aos
/// sheets de adicionar/editar produto. Antes duplicado nos dois builds.
class ProductPricingFields extends StatelessWidget {
  const ProductPricingFields({
    super.key,
    required this.purchaseController,
    required this.saleController,
  });

  final TextEditingController purchaseController;
  final TextEditingController saleController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetSection(
      icon: Icons.payments_outlined,
      title: l10n.productsSectionPricing,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: purchaseController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                label: l10n.productsPurchasePrice,
                validator: (value) => Money.parse(value ?? '') <= 0
                    ? l10n.productsPurchasePriceError
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                controller: saleController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                label: l10n.productsSalePrice,
                validator: (value) => Money.parse(value ?? '') <= 0
                    ? l10n.productsSalePriceError
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        // A2: preview ao vivo dos preços digitados — alinhado com os
        // campos acima, mostrando "= R$ 1.390,00" ANTES de salvar.
        Row(
          children: [
            Expanded(child: MoneyLivePreview(controller: purchaseController)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: MoneyLivePreview(controller: saleController)),
          ],
        ),
      ],
    );
  }
}

/// Bloco de VENDA POR PESO (switch + seletor de unidade) — widget COMUM
/// aos sheets de adicionar/editar produto. Antes duplicado nos dois
/// builds. O RESET da unidade ao alternar o switch (`'kg' : 'un'`) fica
/// no estado do chamador — aqui é só UI.
class ProductWeightFields extends StatelessWidget {
  const ProductWeightFields({
    super.key,
    required this.vendaPorFracao,
    required this.unitLabel,
    required this.onWeightChanged,
    required this.onUnitChanged,
  });

  final bool vendaPorFracao;
  final String unitLabel;
  final ValueChanged<bool> onWeightChanged;
  final ValueChanged<String?> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompactSwitch(
          label: l10n.productsWeighLabel,
          subtitle: l10n.productsWeighHint,
          value: vendaPorFracao,
          onChanged: onWeightChanged,
          embedded: true,
        ),
        if (vendaPorFracao) ...[
          const SizedBox(height: AppSpacing.sm),
          AppPickerField<String>(
            value: unitLabel,
            label: l10n.productsUnitLabel,
            prefixIcon: Icons.scale_outlined,
            items: [
              for (final unit in const ['kg', 'g', 'l', 'ml'])
                DropdownMenuItem(value: unit, child: Text(unit)),
            ],
            onChanged: onUnitChanged,
          ),
        ],
      ],
    );
  }
}

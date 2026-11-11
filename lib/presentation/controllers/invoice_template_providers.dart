import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

/// Configuração do template de documentos PDF (Factura Avançada e Cotação).
///
/// Persistida via `SharedPreferencesAsync` (JSON) — antes o template vivia
/// apenas num campo do `State` da tela e era PERDIDO ao reabrir o app: o
/// PDF saía sempre com o design padrão ("My Business"/cor default).
class InvoiceTemplateConfig {
  InvoiceTemplateConfig({
    this.logoBytes,
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessTaxId = '',
    // Paleta do anexo: default preto #232323.
    // O utilizado persiste nos prefs do utilizador.
    this.primaryColor = AppColors.brandInk,
    this.templateStyle = 'Classic',
  });

  /// Logotipo (bytes PNG/JPEG) — serializado em Base64 no prefs.
  Uint8List? logoBytes;

  /// Nome da empresa; vazio = usar o nome real da loja activa (fallback).
  String businessName;
  String businessAddress;
  String businessPhone;
  String businessTaxId;

  /// Cor principal do template (cabeçalho, tabela e totais do PDF).
  Color primaryColor;

  /// Estilo do layout: 'Classic' | 'Modern' | 'Compact'.
  String templateStyle;

  /// Copia profunda (evita mutação compartilhada entre telas).
  InvoiceTemplateConfig copy() => InvoiceTemplateConfig(
    logoBytes: logoBytes == null ? null : Uint8List.fromList(logoBytes!),
    businessName: businessName,
    businessAddress: businessAddress,
    businessPhone: businessPhone,
    businessTaxId: businessTaxId,
    primaryColor: primaryColor,
    templateStyle: templateStyle,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'logo': logoBytes == null ? null : base64Encode(logoBytes!),
    'name': businessName,
    'address': businessAddress,
    'phone': businessPhone,
    'taxId': businessTaxId,
    'color': primaryColor.toARGB32(),
    'style': templateStyle,
  };

  factory InvoiceTemplateConfig.fromJson(Map<String, Object?> json) =>
      InvoiceTemplateConfig(
        logoBytes: json['logo'] is String
            ? base64Decode(json['logo'] as String)
            : null,
        businessName: json['name'] is String ? json['name'] as String : '',
        businessAddress: json['address'] is String
            ? json['address'] as String
            : '',
        businessPhone: json['phone'] is String ? json['phone'] as String : '',
        businessTaxId: json['taxId'] is String ? json['taxId'] as String : '',
        primaryColor: Color(
          json['color'] is int ? json['color'] as int : 0xFF232323,
        ),
        templateStyle: _knownStyles.contains(json['style'])
            ? json['style']! as String
            : 'Classic',
      );

  static const _knownStyles = {'Classic', 'Modern', 'Compact'};
}

/// Estado do template (síncrono para a UI) + persistência assíncrona.
class InvoiceTemplateNotifier extends Notifier<InvoiceTemplateConfig> {
  /// Chave única no prefs (factura e cotação partilham o mesmo template).
  static const _prefsKey = 'invoice_template:custom_invoice';

  @override
  InvoiceTemplateConfig build() {
    // Carrega o template persistido; enquanto carrega, devolve o default.
    _load();
    return InvoiceTemplateConfig();
  }

  Future<void> _load() async {
    try {
      final raw = await SharedPreferencesAsync().getString(_prefsKey);
      if (raw == null) return;
      final decoded = InvoiceTemplateConfig.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      // Só aplica se o estado actual ainda é o default vazio (não houve
      // edição local enquanto carregava).
      final current = state;
      final untouched =
          current.businessName.isEmpty &&
          current.businessAddress.isEmpty &&
          current.businessPhone.isEmpty &&
          current.businessTaxId.isEmpty &&
          current.logoBytes == null &&
          current.templateStyle == 'Classic' &&
          current.primaryColor == AppColors.brandInk;
      if (untouched) state = decoded;
    } catch (_) {
      // Prefs indisponível (ex.: teste) — mantém default sem quebrar.
    }
  }

  /// Persiste a configuração e actualiza o estado observável.
  Future<void> save(InvoiceTemplateConfig config) async {
    state = config.copy();
    try {
      await SharedPreferencesAsync().setString(
        _prefsKey,
        jsonEncode(state.toJson()),
      );
    } catch (_) {
      // Sem persistência (ex.: teste) — estado em memória já actualizado.
    }
  }
}

/// Template de factura/cotação — partilhado pelas duas telas.
final invoiceTemplateProvider =
    NotifierProvider<InvoiceTemplateNotifier, InvoiceTemplateConfig>(
      InvoiceTemplateNotifier.new,
    );

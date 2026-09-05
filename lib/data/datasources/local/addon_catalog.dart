import '../../../domain/entities/addon.dart';

/// Catálogo de add-ons disponíveis para compra.
///
/// Cada add-on é um serviço extra que o tenant pode activar além do plano
/// base. Os preços são em METICAIS (mercado-alvo Moçambique).
abstract final class AddOnCatalog {
  static List<AddOn> addOns() {
    return const [
      // ─── Factura Personalizada ─────────────────────────
      AddOn(
        id: 'ao_custom_invoice',
        name: 'Factura Personalizada',
        description:
            'Crie facturas profissionais com logotipo, layout customizável '
            'e exportação em PDF. Inclui templates prontos e personalização '
            'de cores, fontes e campos.',
        category: AddOnCategory.invoice,
        priceMonthlyCents: 30000, // MZN 300,00/mês
        iconName: 'receipt_long',
      ),

      // ─── Cotação / Orçamento ──────────────────────────
      AddOn(
        id: 'ao_quotation',
        name: 'Cotação / Orçamento',
        description:
            'Crie e envie cotações e orçamentos para clientes antes da venda. '
            'Inclui conversão automática para venda, validade configurável '
            'e envio por SMS/WhatsApp.',
        category: AddOnCategory.quotation,
        priceMonthlyCents: 25000, // MZN 250,00/mês
        iconName: 'request_quote',
      ),

      // ─── Relatórios Avançados ─────────────────────────
      AddOn(
        id: 'ao_advanced_reports',
        name: 'Relatórios Avançados',
        description:
            'Relatórios financeiros, de vendas e estoque com filtros avançados, '
            'comparativos período a período e exportação em PDF/Excel. '
            'Inclui gráficos interativos e dashboards personalizados.',
        category: AddOnCategory.reports,
        priceMonthlyCents: 35000, // MZN 350,00/mês
        iconName: 'analytics',
      ),

      // ─── Gestão de Funcionários ───────────────────────
      AddOn(
        id: 'ao_employee_mgmt',
        name: 'Gestão de Funcionários',
        description:
            'Controle de ponto (entrada/saída), cálculo automático de '
            'comissões por venda, definição de metas mensais e relatório '
            'de desempenho individual.',
        category: AddOnCategory.employees,
        priceMonthlyCents: 40000, // MZN 400,00/mês
        iconName: 'groups',
        // BLOCKED — FUNCIONALIDADE SEM BACKEND: ponto, comissões e metas
        // não têm tabelas/repositórios reais (só entidades + use cases
        // puros); a gestão REAL de funcionários (contas, lojas, cargos)
        // já existe no módulo Lojas. Fora do marketplace até o schema
        // real existir — nunca vender funcionalidade falsa.
        isAvailable: false,
      ),

      // ─── Multi-Loja Avançado ──────────────────────────
      AddOn(
        id: 'ao_multi_store',
        name: 'Multi-Loja Avançado',
        description:
            'Transferência de estoque entre lojas, relatórios consolidados '
            'comparando lojas, gestão centralizada de preços e promoções '
            'e alertas de reposição automática.',
        category: AddOnCategory.multiStore,
        priceMonthlyCents: 50000, // MZN 500,00/mês
        iconName: 'storefront',
      ),

      // ─── Integração M-Pesa / E-Mola ──────────────────
      AddOn(
        id: 'ao_mobile_money',
        name: 'Integração M-Pesa / E-Mola',
        description:
            'Pagamentos automáticos via mobile money com reconciliação '
            'automática, notificações de recebimento em tempo real '
            'e relatório de transações mobile money.',
        category: AddOnCategory.payments,
        priceMonthlyCents: 45000, // MZN 450,00/mês
        iconName: 'phone_android',
        // BLOCKED — DEPENDÊNCIA EXTERNA: requer API/webhook do provedor
        // (M-Pesa/E-Mola) ainda inexistente; fora do marketplace até a
        // integração real existir (nunca vender funcionalidade falsa).
        isAvailable: false,
      ),
    ];
  }

  /// Lookup rápido por ID.
  static AddOn? findById(String id) {
    try {
      return addOns().firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

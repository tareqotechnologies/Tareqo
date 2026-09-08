import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/share/report_exporter.dart';
import 'package:tareqo/domain/usecases/get_sales_report_use_case.dart';

ReportExportLabels _labels() => const ReportExportLabels(
  title: 'Relatório de vendas',
  store: 'Loja',
  period: 'Período',
  generatedAt: 'Gerado em',
  summary: 'Resumo',
  revenueKpi: 'Faturamento',
  profitKpi: 'Lucro bruto',
  marginKpi: 'Margem',
  bestSellers: 'Mais vendidos',
  rank: 'Posição',
  product: 'Produto',
  quantity: 'Quantidade',
  revenue: 'Receita',
  perDay: 'Vendas por dia',
  day: 'Dia',
  total: 'Total',
  units: 'un.',
  fileNameBase: 'relatorio_vendas',
);

SalesReport _report() => SalesReport(
  totalRevenueCents: 5400,
  totalProfitCents: 1800,
  bestSellers: [
    // Nome com vírgula: campo CSV precisa ser entre-aspado (escape).
    BestSeller(
      productId: 'p1',
      productName: 'Caneta, azul',
      quantity: 12000, // 12 unidades em MILÉSIMOS (W11)
      revenueCents: 2400,
    ),
    BestSeller(
      productId: 'p2',
      productName: 'Caderno',
      quantity: 5000,
      revenueCents: 3000,
    ),
  ],
  perDay: [
    DailySales(day: DateTime(2026, 8, 10), totalCents: 2000),
    DailySales(day: DateTime(2026, 8, 11), totalCents: 3400),
  ],
);

void main() {
  // O buildPdf embute a fonte Inter via rootBundle (asset do pubspec).
  TestWidgetsFlutterBinding.ensureInitialized();

  const exporter = ReportExporter();

  group('ReportExporter.buildCsv', () {
    test('contém cabeçalho, resumo, mais vendidos e vendas por dia', () {
      final csv = exporter.buildCsv(
        report: _report(),
        labels: _labels(),
        storeName: 'Mercado Central',
        periodLabel: 'Este mês',
        generatedAt: DateTime(2026, 8, 10, 14, 30),
      );

      // Cabeçalho: título + loja/período/gerado em.
      expect(csv, contains('Relatório de vendas'));
      expect(csv, contains('Loja;Mercado Central'));
      expect(csv, contains('Período;Este mês'));
      expect(csv, contains('Gerado em;'));

      // Resumo.
      expect(csv, contains('Faturamento;Lucro bruto;Margem'));
      expect(csv, contains('R\$ 54,00;R\$ 18,00;33.3%'));

      // Mais vendidos: rank, produto, qtd, receita. Nomes com vírgula NÃO
      // são entre-aspados (delimitador `;` — a vírgula é decimal da moeda).
      expect(csv, contains('Posição;Produto;Quantidade;Receita'));
      expect(csv, contains('1;Caneta, azul;12 un.;R\$ 24,00'));
      expect(csv, contains('2;Caderno;5 un.;R\$ 30,00'));

      // Vendas por dia.
      expect(csv, contains('Dia;Total'));
      expect(csv, contains('R\$ 20,00'));
      expect(csv, contains('R\$ 34,00'));
    });

    test('escapa aspas e quebras de linha dentro de campos', () {
      final report = SalesReport(
        totalRevenueCents: 100,
        totalProfitCents: 0,
        bestSellers: [
          BestSeller(
            productId: 'p1',
            productName: 'Produto "especial"\ncom quebra',
            quantity: 1000,
            revenueCents: 100,
          ),
        ],
        perDay: const [],
      );

      final csv = exporter.buildCsv(
        report: report,
        labels: _labels(),
        storeName: 'Loja',
        periodLabel: 'Hoje',
        generatedAt: DateTime(2026, 8, 10),
      );

      // Campo entre-aspado com `""` para as aspas internas; a quebra de
      // linha interna fica DENTRO das aspas (o registro é UMA linha lógica).
      expect(
        csv,
        contains('1;"Produto ""especial""\ncom quebra";1 un.;R\$ 1,00'),
      );
      // Apenas uma linha física começa com o registro 1 (a quebra interna
      // não cria um registro novo).
      expect(csv.split('\n').where((l) => l.startsWith('1;')), hasLength(1));
    });

    test('sem dados, mantém os cabeçalhos das seções', () {
      final csv = exporter.buildCsv(
        report: const SalesReport(
          totalRevenueCents: 0,
          totalProfitCents: 0,
          bestSellers: [],
          perDay: [],
        ),
        labels: _labels(),
        storeName: 'Loja',
        periodLabel: 'Hoje',
        generatedAt: DateTime(2026, 8, 10),
      );

      expect(csv, contains('Posição;Produto;Quantidade;Receita'));
      expect(csv, contains('Dia;Total'));
    });
  });

  group('ReportExporter.buildPdf', () {
    test('gera bytes de PDF válidos (%PDF) com resumo e tabelas', () async {
      final bytes = await exporter.buildPdf(
        report: _report(),
        labels: _labels(),
        storeName: 'Mercado Central',
        periodLabel: 'Este mês',
        generatedAt: DateTime(2026, 8, 10, 14, 30),
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      // Trailer padrão presente (documento bem formado). O conteúdo em si é
      // compactado (FlateDecode) — não aparece como texto nos bytes crus.
      final text = String.fromCharCodes(bytes);
      expect(text.trimRight().endsWith('%%EOF'), isTrue);
      expect(text.length, greaterThan(1000));
    });

    test('gera PDF mesmo sem mais vendidos nem vendas por dia', () async {
      final bytes = await exporter.buildPdf(
        report: const SalesReport(
          totalRevenueCents: 0,
          totalProfitCents: 0,
          bestSellers: [],
          perDay: [],
        ),
        labels: _labels(),
        storeName: 'Loja',
        periodLabel: 'Hoje',
        generatedAt: DateTime(2026, 8, 10),
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });
}

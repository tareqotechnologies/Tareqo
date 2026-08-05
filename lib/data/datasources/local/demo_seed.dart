import '../../../domain/entities/customer.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/plan_request.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/store_employee.dart';
import '../../../domain/entities/tenant.dart';

/// Dados de demonstração (seed) para os datasources em memória.
///
/// As datasources por padrão iniciam **vazias** (testes dependem disso);
/// o seed é injetado apenas no ServiceLocator (composition root), para
/// que o app de demonstração abra com conteúdo realista. Datas são
/// relativas a `DateTime.now()` para que períodos (hoje/7 dias/mês)
/// funcionem desde o primeiro dia.
abstract final class DemoSeed {
  /// Usuário demo usado como dono do tenant nas implementações em memória.
  static const demoOwnerUserId = 'demo-owner';

  /// Planos de assinatura (criados pelo super admin em produção).
  static List<Plan> plans() {
    return const [
      Plan(
        id: 'pl1',
        name: 'Essencial',
        description: 'Para começar: 1 loja e até 3 funcionários.',
        priceMonthly: 49.0,
        maxStores: 1,
        maxEmployees: 3,
      ),
      Plan(
        id: 'pl2',
        name: 'Profissional',
        description: 'Para crescer: 3 lojas e até 10 funcionários.',
        priceMonthly: 99.0,
        maxStores: 3,
        maxEmployees: 10,
      ),
      Plan(
        id: 'pl3',
        name: 'Empresa',
        description: 'Para expandir: 10 lojas e até 50 funcionários.',
        priceMonthly: 199.0,
        maxStores: 10,
        maxEmployees: 50,
      ),
    ];
  }

  /// Tenant demo **já aprovado** (dono = [demoOwnerUserId]) para que o app
  /// local abra direto na área de gestão, com loja e funcionário de exemplo.
  static List<Tenant> tenants() {
    return [
      Tenant(
        id: 'tn1',
        ownerUserId: demoOwnerUserId,
        businessName: 'Comercial Dumbhanengue',
        planId: 'pl2',
        status: TenantStatus.approved,
        approvedAt: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 31)),
      ),
    ];
  }

  static List<Store> stores() {
    return const [
      Store(
        id: 'st1',
        tenantId: 'tn1',
        name: 'Loja Centro',
        address: 'Av. Principal, 100',
      ),
      Store(
        id: 'st2',
        tenantId: 'tn1',
        name: 'Loja Shopping',
        address: 'Rua das Flores, 250',
      ),
    ];
  }

  /// Funcionário demo vinculado à Loja Centro (gerente).
  static List<StoreEmployee> employees() {
    return const [
      StoreEmployee(
        id: 'e1',
        tenantId: 'tn1',
        storeId: 'st1',
        userId: 'demo-employee',
        fullName: 'Carlos Funcionário',
        email: 'carlos@dumbhanengue.com',
        role: EmployeeRole.manager,
      ),
    ];
  }

  /// Pedido de upgrade demo já decidido (histórico na aba Plano).
  static List<PlanRequest> planRequests() {
    return const [];
  }

  static List<Product> products() {
    return const [
      // Loja Centro (st1) — o catálogo principal.
      Product(
        id: 'p1',
        storeId: 'st1',
        name: 'Caneta esferográfica',
        description: 'Azul, ponta 0.7mm',
        purchasePrice: 1.0,
        salePrice: 2.0,
        stockQuantity: 100,
      ),
      Product(
        id: 'p2',
        storeId: 'st1',
        name: 'Caderno 96 folhas',
        description: 'Capa dura, pautado',
        purchasePrice: 5.0,
        salePrice: 9.9,
        stockQuantity: 50,
      ),
      Product(
        id: 'p3',
        storeId: 'st1',
        name: 'Arroz 5kg',
        description: 'Tipo 1',
        purchasePrice: 18.0,
        salePrice: 24.0,
        stockQuantity: 30,
      ),
      Product(
        id: 'p4',
        storeId: 'st1',
        name: 'Refrigerante 2L',
        description: 'Cola',
        purchasePrice: 6.0,
        salePrice: 8.5,
        stockQuantity: 20,
      ),
      Product(
        id: 'p5',
        storeId: 'st1',
        name: 'Sabonete',
        description: 'Neutro 90g',
        purchasePrice: 1.5,
        salePrice: 3.0,
        stockQuantity: 4,
      ),
      // Loja Shopping (st2) — catálogo próprio, demonstrando que cada
      // loja tem seu próprio estoque.
      Product(
        id: 'p6',
        storeId: 'st2',
        name: 'Café torrado 500g',
        description: 'Grãos selecionados',
        purchasePrice: 12.0,
        salePrice: 19.9,
        stockQuantity: 15,
      ),
      Product(
        id: 'p7',
        storeId: 'st2',
        name: 'Água mineral 1.5L',
        description: 'Garrafa',
        purchasePrice: 1.5,
        salePrice: 3.5,
        stockQuantity: 24,
      ),
    ];
  }

  static List<Sale> sales() {
    final now = DateTime.now();
    return [
      Sale(
        id: 's1',
        items: const [
          SaleItem(
            productId: 'p1',
            productName: 'Caneta esferográfica',
            quantity: 2,
            unitPrice: 2.0,
          ),
          SaleItem(
            productId: 'p2',
            productName: 'Caderno 96 folhas',
            quantity: 1,
            unitPrice: 9.9,
          ),
        ],
        totalAmount: 13.9,
        paymentMethod: PaymentMethod.pix,
        dateTime: now.subtract(const Duration(hours: 2)),
      ),
      Sale(
        id: 's2',
        items: const [
          SaleItem(
            productId: 'p3',
            productName: 'Arroz 5kg',
            quantity: 1,
            unitPrice: 24.0,
          ),
        ],
        totalAmount: 24.0,
        paymentMethod: PaymentMethod.cash,
        dateTime: now.subtract(const Duration(days: 1)),
      ),
      Sale(
        id: 's3',
        items: const [
          SaleItem(
            productId: 'p4',
            productName: 'Refrigerante 2L',
            quantity: 2,
            unitPrice: 8.5,
          ),
        ],
        totalAmount: 17.0,
        paymentMethod: PaymentMethod.debitCard,
        dateTime: now.subtract(const Duration(days: 3)),
      ),
      // Venda da Loja Shopping (st2) — histórico separado por loja.
      Sale(
        id: 's4',
        storeId: 'st2',
        items: const [
          SaleItem(
            productId: 'p6',
            productName: 'Café torrado 500g',
            quantity: 1,
            unitPrice: 19.9,
          ),
        ],
        totalAmount: 19.9,
        paymentMethod: PaymentMethod.pix,
        dateTime: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<Customer> customers() {
    return const [
      // Todos os clientes demo pertencem à Loja Centro (st1).
      Customer(
        id: 'c1',
        storeId: 'st1',
        name: 'João da Silva',
        phone: '(11) 99911-1111',
        email: 'joao@email.com',
      ),
      Customer(
        id: 'c2',
        storeId: 'st1',
        name: 'Maria Souza',
        phone: '(11) 98822-2222',
        email: 'maria@email.com',
      ),
      Customer(
        id: 'c3',
        storeId: 'st1',
        name: 'Pedro Alves',
        phone: '(11) 97733-3333',
        email: 'pedro@email.com',
      ),
      Customer(
        id: 'c4',
        storeId: 'st1',
        name: 'Ana Lima',
        phone: '(11) 96644-4444',
        email: 'ana@email.com',
      ),
    ];
  }

  /// Compras de mercadoria (entrada de estoque + saída no caixa).
  static List<Purchase> purchases() {
    final now = DateTime.now();
    return [
      // Compras da Loja Centro (st1).
      Purchase(
        id: 'pc1',
        storeId: 'st1',
        supplierName: 'Distribuidora Norte',
        items: const [
          PurchaseItem(
            productId: 'p3',
            productName: 'Arroz 5kg',
            quantity: 10,
            unitPrice: 18.0,
          ),
          PurchaseItem(
            productId: 'p4',
            productName: 'Refrigerante 2L',
            quantity: 5,
            unitPrice: 6.0,
          ),
        ],
        totalAmount: 210.0,
        dateTime: now.subtract(const Duration(days: 4)),
      ),
      Purchase(
        id: 'pc2',
        storeId: 'st1',
        supplierName: 'Fornecedor Central',
        items: const [
          PurchaseItem(
            productId: 'p1',
            productName: 'Caneta esferográfica',
            quantity: 50,
            unitPrice: 1.0,
          ),
          PurchaseItem(
            productId: 'p2',
            productName: 'Caderno 96 folhas',
            quantity: 20,
            unitPrice: 5.0,
          ),
        ],
        totalAmount: 150.0,
        dateTime: now.subtract(const Duration(days: 8)),
      ),
    ];
  }

  /// Cada venda ([sales]) tem sua entrada no caixa; a pendência `t4`
  /// (fiado do João) está vinculada à dívida `d1` via [debtId] — ao
  /// quitar, o SettleDebtUseCase marca a MESMA transação como paga.
  static List<FinancialTransaction> transactions() {
    final now = DateTime.now();
    return [
      FinancialTransaction(
        id: 't1',
        description: 'Venda via PIX',
        amount: 13.9, // = s1
        type: TransactionType.income,
        category: 'Vendas',
        date: now.subtract(const Duration(hours: 2)),
      ),
      FinancialTransaction(
        id: 't2',
        description: 'Energia elétrica',
        amount: 180,
        type: TransactionType.expense,
        category: 'Contas',
        date: now.subtract(const Duration(hours: 5)),
      ),
      FinancialTransaction(
        id: 't3',
        description: 'Venda em dinheiro',
        amount: 24.0, // = s2
        type: TransactionType.income,
        category: 'Vendas',
        date: now.subtract(const Duration(days: 1)),
      ),
      FinancialTransaction(
        id: 't4',
        description: 'Venda fiado (João)',
        amount: 25.0, // = d1 (João da Silva)
        type: TransactionType.income,
        category: 'Fiado',
        date: now.subtract(const Duration(days: 1)),
        status: TransactionStatus.pending,
        debtId: 'd1',
      ),
      FinancialTransaction(
        id: 't5',
        description: 'Aluguel da loja',
        amount: 900,
        type: TransactionType.expense,
        category: 'Contas',
        date: now.subtract(const Duration(days: 2)),
      ),
      FinancialTransaction(
        id: 't6',
        description: 'Venda no débito',
        amount: 17.0, // = s3
        type: TransactionType.income,
        category: 'Vendas',
        date: now.subtract(const Duration(days: 3)),
      ),
      FinancialTransaction(
        id: 't7',
        description: 'Compra de mercadoria',
        amount: 320,
        type: TransactionType.expense,
        category: 'Compras',
        date: now.subtract(const Duration(days: 4)),
      ),
      // Saídas das compras demo (pc1 = 210, pc2 = 150).
      FinancialTransaction(
        id: 't8',
        description: 'Compra — Distribuidora Norte',
        amount: 210.0,
        type: TransactionType.expense,
        category: 'Compras',
        date: now.subtract(const Duration(days: 4)),
      ),
      FinancialTransaction(
        id: 't9',
        description: 'Compra — Fornecedor Central',
        amount: 150.0,
        type: TransactionType.expense,
        category: 'Compras',
        date: now.subtract(const Duration(days: 8)),
      ),
      // Movimento da Loja Shopping (st2) — caixa separado por loja.
      FinancialTransaction(
        id: 't10',
        storeId: 'st2',
        description: 'Venda via PIX (Shopping)',
        amount: 19.9, // = s4
        type: TransactionType.income,
        category: 'Vendas',
        date: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<Debt> debts() {
    final now = DateTime.now();
    return [
      Debt(
        id: 'd1',
        personName: 'João da Silva',
        amount: 25.0,
        dueDate: now.add(const Duration(days: 3)),
        isCustomerDebt: true,
        customerId: 'c1',
      ),
      Debt(
        id: 'd2',
        personName: 'Maria Souza',
        amount: 60.0,
        dueDate: now.subtract(const Duration(days: 2)),
        isCustomerDebt: true,
        customerId: 'c2',
      ),
      Debt(
        id: 'd3',
        personName: 'Pedro Alves',
        amount: 15.5,
        dueDate: now.add(const Duration(days: 10)),
        isCustomerDebt: true,
        customerId: 'c3',
      ),
      // A pagar (fornecedor) — filtrada pelo GetPendingDebtsUseCase.
      Debt(
        id: 'd4',
        personName: 'Distribuidora Norte',
        amount: 120.0,
        dueDate: now.add(const Duration(days: 5)),
        isCustomerDebt: false,
      ),
      // Já quitada — aparece no histórico de quitações (aba do Crédito).
      Debt(
        id: 'd5',
        personName: 'Ana Lima',
        amount: 40.0,
        dueDate: now.subtract(const Duration(days: 20)),
        isCustomerDebt: true,
        isPaid: true,
        paidAt: now.subtract(const Duration(days: 10)),
        customerId: 'c4',
      ),
    ];
  }
}

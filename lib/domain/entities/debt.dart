import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt.freezed.dart';
part 'debt.g.dart';

/// Entidade de domínio que representa uma dívida ("fiado").
///
/// [isCustomerDebt] indica a direção:
/// - `true` → **a receber**: o cliente deve ao comerciante
/// (contas a receber / contas de cliente);
/// - `false` → **a pagar**: o comerciante deve ao fornecedor.
///
/// A dívida em aberto é, por natureza, **pendente** — o [Debt] nasce
/// com [isPaid] `false` e é quitado pelo SettleDebtUseCase (que marca a
/// baixa e registra a entrada no caixa).
@freezed
abstract class Debt with _$Debt {
 @Assert('amountCents >= 0', 'O valor da dívida deve ser positivo.')
 const factory Debt({
 required String id,
 // Número SEQUENCIAL da dívida DENTRO da loja (ex.: D-00001, D-00002).
 // Atribuído pelo banco no insert — SQLite: MAX+1 por loja dentro da
 // transação; Supabase: RPC register_debt com advisory lock por loja.
 // O default 0 nunca é persistido (é substituído na gravação).
 @Default(0) int number,
 // Loja dona do fiado (Fase 2 do multi-tenancy). Cada loja tem seu
 // próprio "a receber / a pagar".
 @Default('st1') String storeId,
 required String personName,
 // Valor em CENTAVOS inteiros (W4 — migração de dinheiro para
 // centavos; o banco persiste BIGINT/INTEGER).
 required int amountCents,
 required DateTime dueDate,
 required bool isCustomerDebt,
 @Default(false) bool isPaid,
 // Data da baixa (carimbada pelo SettleDebtUseCase) — null enquanto
 // a dívida estiver pendente. Alimenta o histórico de quitações.
 DateTime? paidAt,
 // Vínculo opcional com o cadastro de clientes. O [personName] continua
 // sendo o "snapshot" exibido no histórico — se o cadastro do cliente
 // mudar de nome depois, a dívida mantém o nome da época.
 String? customerId,
 }) = _Debt;

 factory Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);
}

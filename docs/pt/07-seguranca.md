# 07 — Segurança

Este documento cobre as decisões de segurança do app: **armazenamento seguro** de segredos, limites de responsabilidade entre o app e o Supabase, e boas práticas por plataforma.

---

## Armazenamento seguro (`SecureStorageService`)

`lib/core/security/secure_storage_service.dart` encapsula a persistência **criptografada** de tokens de acesso, tokens de renovação e chaves de API.

### Arquitetura

```text
SecureStorageService
  └─ SecureStorageBackend (interface)          ← abstraído para testes
       ├─ FlutterSecureStorageBackend          ← real: flutter_secure_storage
       └─ (in-memory backend nos testes)
```

- **Chaves centralizadas** em `SecureStorageKeys`: `accessToken`, `refreshToken`, `apiKey` — evita erros de digitação e permite auditar o que é tratado como sensível.
- **API:** `write`, `read`, `delete`, `contains`.
- **Registrado no GetIt** (`ServiceLocator`) — ponto único de acesso para a camada data/presentation.

### Por que não usar `shared_preferences` para dados sensíveis?

| Aspecto | `shared_preferences` | `flutter_secure_storage` |
| ------- | -------------------- | ------------------------ |
| Local físico | Arquivo de preferências em texto plano | **Keychain** (iOS/macOS) e **Android Keystore** |
| Criptografia | Nenhuma — valor legível em disco | Criptografado; no Android a chave (AES-GCM) é gerada e guardada no Keystore, amarrada ao hardware |
| Acesso | Qualquer processo com leitura do arquivo | Protegido pelo SO; no iOS pode exigir biometria (Face ID/Touch ID) |
| Backup/extração | Legível em backups, root/JB ou extração de APK | Criptografado de ponta a ponta |
| Caso de uso ideal | Preferências de UI (tema, idioma, filtros) | Tokens de sessão, refresh tokens, chaves de API, segredos |

### Por que isso protege a conta do comerciante

1. **O token é a senha.** Com o token de sessão (ou refresh token) em mãos, um atacante acessa a conta sem precisar da senha.
2. **Criptografia amarrada ao dispositivo:** a chave mestra vive no **Android Keystore** (hardware-backed, TEE) / **Keychain** com enclave seguro — copiar o arquivo não basta sem a chave do hardware.
3. **Custo de ataque alto:** comprometer o SO/hardware é inviável em escala (mesma confiança que bancos usam).
4. **Acesso condicionado ao usuário (iOS):** o Keychain pode exigir biometria.

---

## Limite de responsabilidade (não duplicar a sessão!)

A **sessão do Supabase** (access + refresh token do login) **já é persistida internamente** pelo `supabase_flutter` na própria instância do `flutter_secure_storage` (chaves `sb-...-auth-token`), com renovação automática.

Por isso o `SecureStorageService` **não deve gravar esses tokens**. Ele existe para **segredos do aplicativo**:

- chaves de API de serviços externos (ex.: gateway de pagamento);
- segredos de configuração;
- qualquer credencial que a camada data/presentation precise guardar.

Manter essa fronteira evita **dois lugares gravando a sessão** (fonte de conflito e de confusão de auditoria).

---

## RLS (Row Level Security) no Supabase

- A anon key é **pública por design** — embutida no cliente. A segurança real vem do banco:
  ```sql
  -- regra de isolamento por tenant
  user_id = auth.uid()
  ```
- Mesmo que um bug na UI vaze dados, o **banco os filtra**.
- **Nunca** coloque a *service role key* no cliente (ela ignora o RLS).

---

## Ressalvas por plataforma (precisão técnica)

| Plataforma | Mecanismo | Nível de proteção |
| ---------- | --------- | ----------------- |
| Android/iOS | Android Keystore (AES-GCM, chave na TEE) / Keychain com enclave | **Hardware-backed** — onde dados críticos devem residir |
| Windows | DPAPI (vinculado à conta do usuário do SO) | Razoável, sem enclave dedicado |
| Linux | libsecret | Razoável, sem enclave dedicado |
| Web | Chave de criptografia guardada no `localStorage` | **Mais fraco** — não é hardware-backed |

> ⚠️ Para **segredos críticos, priorize mobile**; na web, restrinja o que é armazenado ou combine com medidas de servidor.

---

## Outras práticas do projeto

- **Erros de autenticação genéricos na UI:** `debugPrint` com detalhes para diagnóstico; SnackBar amigável ao usuário (não expõe detalhes internos do provedor).
- **Regras de negócio no domínio, salvaguardas no banco:** valores não negativos são validados nos casos de uso **e** por `CHECK` no SQLite (defesa em profundidade).
- **SQL parametrizado** em todos os datasources SQLite (prepared statements — nunca concatenação de strings), evitando injeção de SQL.

---

## Documentos relacionados

- [Autenticação](06-autenticacao.md) — fluxo de sessão e onde cada token vive.
- [Camada de dados](04-dados.md) — schema e salvaguardas do banco.
- [Arquitetura](02-arquitetura.md) — onde a segurança se encaixa na estrutura.

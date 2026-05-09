# Changelog — Aeterna Protocol

## v2.4.0 — Sealed (gennaio 2026)

### 🆕 Emergency Sealed Envelope (k-of-n)
- **`ShamirService`** — Shamir Secret Sharing su GF(256) (AES poly 0x11b),
  split / combine canonici, encoding base64 url-safe per share.
- **`SealedEnvelopeService`** — l'utente sigilla un messaggio: una chiave
  AES-256 random cifra il payload (AES-GCM), poi viene splittata k-of-n e
  ogni share consegnata a un erede. Il payload cifrato è persistito; la
  chiave non è mai memorizzata. Solo il quorum di eredi può aprire.
- **UI**: `SealedEnvelopeScreen` — flusso crea (titolo, messaggio, n, k),
  shares mostrate UNA volta con copia individuale.

### 🛠️ Settings rifatto
- Voce **Imposta/Cambia PIN** (route `/pin-setup`).
- **Rigenera PIN e Recovery Key** con conferma di sicurezza.
- Toggle **Blocca screenshot** (FLAG_SECURE).
- Voce **Sealed Envelope** in sezione "Eredità".
- Logout ora blocca il vault e fa redirect a `/auth`.

### 🔄 Migrazione automatica v2.2 → v2.3+
- **`MigrationService`** — al primo unlock dopo upgrade ricifra
  eventuali blob cifrati con il vecchio salt costante usando il nuovo
  salt random. Idempotente (flag in `SharedPreferences`).

### 🛡️ Hardening Android
- **MainActivity.kt**: `FLAG_SECURE` attivo di default + MethodChannel
  `aeterna/screenshot` per toggle runtime.
- **proguard-rules.pro**: regole rinforzate per `pointycastle`,
  `bouncycastle`, `tink`; rimozione log Android in release.
- **AndroidManifest.xml**: `USE_BIOMETRIC` già presente, confermato.

### 🧹 Codice ripulito (mismatch storico v2.2)
- **`AuthNotifier`**: PBKDF2-SHA256 100k iter + salt random 16-byte,
  confronto in tempo costante. Niente più riferimenti a metodi statici
  inesistenti su `EncryptionService`.
- **`AuthScreen`**: usa `authProvider` (Riverpod), integra setup → PIN
  setup automatico al primo login, sblocca `lockProvider`.
- **`VaultScreen`**: cifratura tramite `vaultRepositoryProvider`
  (rimossi i riferimenti rotti a `EncryptionService.encrypt(Uint8List)`).

### 📦 Files
**Nuovi (v2.4):**
- `lib/core/services/shamir_service.dart`
- `lib/core/services/sealed_envelope_service.dart`
- `lib/core/services/migration_service.dart`
- `lib/core/services/screenshot_protection.dart`
- `lib/features/envelope/sealed_envelope_screen.dart`

**Modificati (v2.4):**
- `pubspec.yaml` — version `2.4.0+1`
- `lib/main.dart` — `ScreenshotProtection.enable()` + `migrateIfNeeded()`
- `lib/core/providers.dart` — Shamir, SealedEnvelope, Migration
- `lib/core/router/app_router.dart` — route `/sealed-envelope`
- `lib/features/settings/settings_screen.dart` — PIN mgmt + screenshot toggle + envelope
- `lib/features/auth/providers/auth_provider.dart` — refactor pulito
- `lib/features/auth/auth_screen.dart` — Riverpod-based, integra `/pin-setup`
- `lib/features/vault/vault_screen.dart` — usa `vaultRepositoryProvider`
- `android/app/src/main/kotlin/.../MainActivity.kt` — FLAG_SECURE + channel
- `android/app/proguard-rules.pro` — hardening release build

### 🚦 Note
1. Le shares dell'envelope NON possono essere rigenerate: in caso di
   smarrimento occorre creare un nuovo envelope. La chiave AES non è
   conservata.
2. Il toggle screenshot agisce a livello di Activity (Android). Su iOS
   è un no-op silenzioso (richiederebbe overlay nello AppDelegate).
3. La migrazione legacy gira UNA volta. Se hai già fatto onboarding
   v2.3 da zero, il flag è già settato e non viene rieseguita.

---

## v2.3.0 — Secure Vault (gennaio 2026)
Vedi sezione precedente.

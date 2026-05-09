# Digital Vault Heritage v2.5 - API Documentation

## Overview

This document provides comprehensive API documentation for the Digital Vault Heritage application, including security services, encryption methods, and subscription management.

## Table of Contents

- [Security Service API](#security-service-api)
- [Encryption Service API](#encryption-service-api)
- [Dead Man's Switch API](#dead-mans-switch-api)
- [Subscription Service API](#subscription-service-api)
- [Error Handling API](#error-handling-api)
- [Authentication API](#authentication-api)
- [Vault Management API](#vault-management-api)

---

## Security Service API

### Input Sanitization

```dart
String sanitizeInput(String input, {int maxLength = 1000})
```

**Description**: Sanitizes user input to prevent XSS, SQL injection, and other attacks.

**Parameters**:
- `input`: Raw user input string
- `maxLength`: Maximum allowed length (default: 1000)

**Returns**: Sanitized string

**Throws**: `SecurityViolationException` if input contains malicious content

**Example**:
```dart
try {
  String clean = SecurityService().sanitizeInput(userInput, maxLength: 255);
  // Use sanitized input
} on SecurityViolationException catch (e) {
  // Handle security violation
}
```

### Rate Limiting

```dart
Future<bool> checkLoginRateLimit(String identifier)
Future<bool> checkPinRateLimit()
Future<bool> checkRecoveryRateLimit()
```

**Description**: Checks if the user has exceeded rate limits for authentication attempts.

**Parameters**:
- `identifier`: Unique user identifier (for login attempts)

**Returns**: `true` if attempt is allowed, `false` if rate limited

**Rate Limits**:
- Login: 5 attempts per 15 minutes
- PIN: 5 attempts per 10 minutes
- Recovery: 3 attempts per hour

### Session Management

```dart
Future<void> createSession(String userId)
Future<bool> isSessionValid()
Future<void> updateSessionActivity()
Future<void> invalidateSession()
```

**Description**: Manages user sessions with automatic timeout and security validation.

**Parameters**:
- `userId`: Unique user identifier

**Session Configuration**:
- Timeout: 24 hours of inactivity
- Maximum Age: 7 days
- Automatic activity tracking

---

## Encryption Service API

### Key Derivation

```dart
Future<SecretKey> deriveKey(String masterKey, List<int> salt)
```

**Description**: Derives encryption key from master key using PBKDF2.

**Parameters**:
- `masterKey`: User's master key
- `salt`: Cryptographically secure salt (16 bytes)

**Returns**: Derived 256-bit encryption key

**Configuration**:
- Algorithm: PBKDF2
- HMAC: SHA-256
- Iterations: 100,000
- Key Length: 256 bits

### Data Encryption

```dart
Future<Map<String, String>> encrypt({
  required String data,
  required SecretKey key,
})
```

**Description**: Encrypts data using AES-256-GCM with authenticated encryption.

**Parameters**:
- `data`: Plaintext data to encrypt
- `key`: Encryption key

**Returns**: Map containing:
- `cipher`: Base64-encoded ciphertext
- `nonce`: Base64-encoded nonce
- `mac`: Base64-encoded authentication tag

### Data Decryption

```dart
Future<String> decrypt({
  required Map<String, String> payload,
  required SecretKey key,
})
```

**Description**: Decrypts data and verifies integrity using AES-256-GCM.

**Parameters**:
- `payload`: Encryption payload (cipher, nonce, mac)
- `key`: Encryption key

**Returns**: Decrypted plaintext string

**Throws**: `Exception` if decryption fails or integrity check fails

---

## Dead Man's Switch API

### Configuration

```dart
class DeadMansSwitchConfig {
  final int intervalDays;
  final int gracePeriodDays;
  final List<String> heirEmails;
  final bool requireMultipleConfirmations;
  final int requiredConfirmations;
}
```

### Activation

```dart
Future<void> activate(DeadMansSwitchConfig config)
```

**Description**: Activates the Dead Man's Switch with specified configuration.

**Parameters**:
- `config`: Switch configuration object

**Validation Rules**:
- At least one heir email required
- Required confirmations cannot exceed heir count
- All email addresses must be valid format
- Interval must be between 30 and 365 days

### Check-in

```dart
Future<void> checkIn()
```

**Description**: Performs a heartbeat check-in to reset the inactivity timer.

**Automatic Features**:
- Hourly automatic heartbeat
- 24-hour inactivity detection
- Grace period notifications

### Heir Confirmation

```dart
Future<bool> confirmHeirAccess(String email, String token)
```

**Description**: Confirms heir access using secure token.

**Parameters**:
- `email`: Heir's email address
- `token`: Secure confirmation token

**Returns**: `true` if confirmation successful, `false` otherwise

### State Management

```dart
Future<DeadMansSwitchState> getState()
```

**Description**: Gets current state of the Dead Man's Switch.

**State Properties**:
- `isActive`: Whether switch is active
- `lastCheckIn`: Last successful check-in time
- `nextCheckIn`: When next check-in is due
- `isGracePeriodActive`: Whether grace period is active
- `isTriggered`: Whether switch has been triggered
- `hasRequiredConfirmations`: Whether enough heirs have confirmed

---

## Subscription Service API

### Subscription Tiers

```dart
enum SubscriptionTier {
  free('free', 'Free', 0, 'basic_features'),
  premium('premium', 'Premium', 9999, 'all_features'),
  lifetime('lifetime', 'Lifetime', 99999, 'lifetime_access');
}
```

### Subscription Management

```dart
Future<Subscription> createSubscription(
  String userId,
  SubscriptionTier tier, {
  String? paymentMethodId,
  String? stripeCustomerId,
})
```

**Description**: Creates a new subscription for the user.

**Parameters**:
- `userId`: User identifier
- `tier`: Subscription tier
- `paymentMethodId`: Stripe payment method ID (for paid tiers)
- `stripeCustomerId`: Existing Stripe customer ID

**Returns**: Created subscription object

### Access Control

```dart
Future<bool> hasPremiumAccess(String userId)
```

**Description**: Checks if user has active premium access.

**Parameters**:
- `userId`: User identifier

**Returns**: `true` if user has premium access, `false` otherwise

### Webhook Handling

```dart
Future<void> handleStripeWebhook(String payload, String signature)
```

**Description**: Processes Stripe webhook events for subscription management.

**Parameters**:
- `payload`: Webhook payload from Stripe
- `signature`: Stripe signature for verification

**Supported Events**:
- `invoice.payment_succeeded`
- `invoice.payment_failed`
- `customer.subscription.deleted`
- `customer.subscription.updated`

---

## Error Handling API

### Error Categories

```dart
enum ErrorCategory {
  network,
  authentication,
  encryption,
  storage,
  validation,
  system,
  user,
}
```

### Error Handling

```dart
Future<void> handleError(
  dynamic error, {
  StackTrace? stackTrace,
  String? userId,
  ErrorCategory? category,
  Map<String, dynamic>? context,
  List<String>? suggestedActions,
})
```

**Description**: Handles and logs errors with user-friendly feedback.

**Parameters**:
- `error`: The error to handle
- `stackTrace`: Stack trace for debugging
- `userId`: User identifier
- `category`: Error category
- `context`: Additional context information
- `suggestedActions`: User-friendly recovery suggestions

### Error Stream

```dart
Stream<AppError> get errorStream
```

**Description**: Stream of application errors for UI components.

**Usage**:
```dart
ErrorHandlingService().errorStream.listen((error) {
  // Handle error in UI
  showErrorDialog(error.message, error.suggestedActions);
});
```

---

## Authentication API

### PIN Service

```dart
Future<void> setPin(String pin)
Future<PinVerifyResult> verifyPin(String pin)
Future<bool> isPinSet()
Future<void> clearPin()
```

**PIN Requirements**:
- Length: 4-8 digits
- Characters: Numeric only
- Rate limiting: 5 attempts per 10 minutes
- Lockout: Automatic after failed attempts

### Recovery Key Service

```dart
Future<String> generateAndStore()
Future<bool> verify(String input)
Future<bool> isSet()
Future<void> clear()
```

**Recovery Key Format**:
- Length: 40 characters (200 bits entropy)
- Encoding: Base32 without ambiguous characters
- Groups: 5-character groups separated by hyphens
- Storage: Only hash stored, not the key itself

---

## Vault Management API

### Document Operations

```dart
Future<void> addDoc(VaultDoc doc)
Future<void> removeDoc(String id)
Future<void> updateDocument(String id, VaultDoc updatedDoc)
Future<void> toggleHeirShare(String id)
```

### Document Validation

```dart
void _validateDocument(VaultDoc doc)
```

**Validation Rules**:
- Name length: Maximum 255 characters
- Size limit: Maximum 100MB per document
- Vault limit: Maximum 100 documents (premium)
- Required fields: name, extension, ciphertextUrl

### Vault Statistics

```dart
Map<String, dynamic> getVaultStats()
```

**Returns**: Statistics including:
- Total documents
- Total storage used
- Shared documents count
- Maximum limits
- Utilization percentage

---

## Security Configuration

### Rate Limiting Configuration

```dart
static const int maxLoginAttempts = 5;
static const Duration loginAttemptWindow = Duration(minutes: 15);
static const int maxPinAttempts = 5;
static const Duration pinAttemptWindow = Duration(minutes: 10);
static const int maxRecoveryAttempts = 3;
static const Duration recoveryAttemptWindow = Duration(hours: 1);
```

### Session Configuration

```dart
static const Duration sessionTimeout = Duration(hours: 24);
static const Duration maxSessionAge = Duration(days: 7);
```

### Encryption Configuration

```dart
static const int keyDerivationIterations = 100000;
static const int saltLength = 16;
static const int keyLength = 32; // 256 bits
```

---

## Error Codes

### Security Errors

- `SECURITY_VIOLATION`: Input contains malicious content
- `RATE_LIMIT_EXCEEDED`: Too many authentication attempts
- `SESSION_EXPIRED`: User session has expired
- `INVALID_TOKEN`: Security token is invalid

### Encryption Errors

- `ENCRYPTION_FAILED`: Data encryption failed
- `DECRYPTION_FAILED`: Data decryption failed
- `INVALID_KEY_FORMAT`: Encryption key format is invalid
- `KEY_DERIVATION_FAILED`: Key derivation process failed

### Subscription Errors

- `PAYMENT_FAILED`: Payment processing failed
- `SUBSCRIPTION_NOT_FOUND`: Subscription does not exist
- `INSUFFICIENT_PRIVILEGES`: User lacks required privileges
- `WEBHOOK_VERIFICATION_FAILED`: Webhook signature verification failed

### Vault Errors

- `VAULT_FULL`: Vault storage limit exceeded
- `DOCUMENT_TOO_LARGE`: Document size exceeds limit
- `INVALID_DOCUMENT_FORMAT`: Document format not supported
- `DOCUMENT_NOT_FOUND`: Document does not exist

---

## Security Best Practices

### For Developers

1. **Always sanitize inputs**: Use `SecurityService.sanitizeInput()` for all user input
2. **Use secure storage**: Never store sensitive data in SharedPreferences
3. **Implement rate limiting**: Protect all authentication endpoints
4. **Log security events**: Use `SecurityService.logSecurityEvent()` for audit trails
5. **Handle errors gracefully**: Use `ErrorHandlingService` for comprehensive error management

### For Users

1. **Use strong master keys**: Let the app generate cryptographically secure keys
2. **Enable biometric authentication**: Use device biometrics when available
3. **Set up recovery keys**: Store recovery keys securely offline
4. **Configure Dead Man's Switch**: Set appropriate intervals and heir confirmations
5. **Keep app updated**: Always use the latest version with security patches

---

## Testing

### Unit Tests

```bash
flutter test test/security_service_test.dart
flutter test test/encryption_service_test.dart
flutter test test/subscription_service_test.dart
```

### Integration Tests

```bash
flutter test integration_test/dead_mans_switch_test.dart
flutter test integration_test/authentication_flow_test.dart
```

### Security Tests

```bash
flutter test test/security/rate_limiting_test.dart
flutter test test/security/input_validation_test.dart
flutter test test/security/encryption_test.dart
```

---

## Support

For API support and questions:
- **Documentation**: https://docs.digitalvault.com
- **Support Email**: api-support@digitalvault.com
- **Security Issues**: security@digitalvault.com

---

*This API documentation is for version 2.5.0 of the Digital Vault Heritage application.*

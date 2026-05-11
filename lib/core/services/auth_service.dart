// v2.3 — Servizio di autenticazione biometrica con fallback PIN.
import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// True se il device supporta una qualche forma di biometria.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Sblocca con biometria. `biometricOnly: false` consente al sistema di
  /// proporre il PIN/password del device come fallback nativo. Il PIN della
  /// nostra app (offline) è gestito separatamente da PinService.
  Future<bool> authenticate({
    String reason = 'Accedi al tuo vault',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

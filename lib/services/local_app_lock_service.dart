// lib/services/local_app_lock_service.dart
// Device-backed local app lock. This is not account authentication; it asks the
// OS to verify the current device owner with Face ID, Touch ID, fingerprint,
// or the configured device PIN/passcode.

import 'package:local_auth/local_auth.dart';

class LocalAppLockService {
  final LocalAuthentication _auth;

  LocalAppLockService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  Future<bool> get isSupported async {
    try {
      return _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return _auth.authenticate(
        localizedReason: 'Unlock Digital Weinke',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

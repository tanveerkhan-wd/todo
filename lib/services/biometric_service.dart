import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service for optional biometric / PIN lock on app entry.
///
/// Uses platform keystore (Android Biometric / iOS FaceID/TouchID).
/// Falls back to device PIN/pattern when biometrics are unavailable.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device has biometric hardware + enrolled credentials.
  Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Available biometric types (face, fingerprint, etc.).
  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Attempt biometric / PIN authentication.
  ///
  /// Returns `true` if the user successfully authenticated.
  Future<bool> authenticate({
    String reason = 'Unlock Todo',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Stop any active authentication session.
  Future<void> stopAuthentication() async {
    await _auth.stopAuthentication();
  }
}

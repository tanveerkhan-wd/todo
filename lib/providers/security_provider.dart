import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_service.dart';

/// Service instance provider.
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

/// Whether biometric / PIN lock is enabled on app entry.
final biometricLockEnabledProvider = StateProvider<bool>((ref) => false);

/// Whether the user has passed the biometric challenge in this session.
final biometricUnlockedProvider = StateProvider<bool>((ref) => false);

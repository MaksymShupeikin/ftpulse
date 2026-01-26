import 'package:ftpulse/core/imports.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        debugPrint("Biometrics not available on this device.");
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Scan your face or fingerprint to connect',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric authentication required!',
            cancelButton: 'No thanks',
          ),
        ],
      );
    } on PlatformException catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }
}

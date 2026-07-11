// test/auth_service_test.dart
// Tests for the provider-agnostic auth facade.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/models/auth_models.dart';
import 'package:f3_nation_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('continueAsGuest creates and persists a guest user', () async {
    final auth = LocalAuthService();
    await auth.load();

    final user = await auth.continueAsGuest(displayName: 'Digital');

    expect(user.isGuest, isTrue);
    expect(user.displayName, 'Digital');
    expect(user.identities.single.provider, AuthProvider.guest);

    final reloaded = LocalAuthService();
    await reloaded.load();
    expect(reloaded.currentUser?.id, user.id);
    expect(reloaded.isSignedIn, isTrue);
  });

  test('signOut clears persisted user', () async {
    final auth = LocalAuthService();
    await auth.load();
    await auth.continueAsGuest(displayName: 'Digital');

    await auth.signOut();

    final reloaded = LocalAuthService();
    await reloaded.load();
    expect(reloaded.currentUser, isNull);
  });

  test('Slack sign-in is explicitly unavailable until backend exists',
      () async {
    final auth = LocalAuthService();
    await auth.load();

    expect(
      auth.signInWithSlack,
      throwsA(isA<AuthUnavailableException>()),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';

void main() {
  testWidgets('debug failing test', (tester) async {
    const dummyDriver = UserModel(
      id: 'driver_123',
      name: 'Test Driver',
      email: 'driver@test.com',
      phoneNumber: '+919876543210',
      role: UserRole.driver,
      isUnionVerified: true,
      vehicleInfo: 'Auto Rickshaw',
    );
    final driverController = AuthController(initialState: const AuthState.authenticated(dummyDriver));

    final app = MaterialApp(
      initialRoute: AppRoutes.riderProfile,
      onGenerateRoute: (settings) => AppRoutes.generateRoute(
        settings,
        authController: driverController,
      ),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    debugDumpApp();
  });
}

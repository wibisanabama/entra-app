import 'package:entra_app/widgets/organizer_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('organizer shell switches between its three primary destinations', (tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return OrganizerShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/dashboard', builder: (_, _) => const Text('Dashboard organizer')),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/events', builder: (_, _) => const Text('Daftar event')),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/withdrawals', builder: (_, _) => const Text('Saldo organizer')),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Dashboard organizer'), findsOneWidget);

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar event'), findsOneWidget);

    await tester.tap(find.text('Keuangan'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo organizer'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/attendee_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/withdrawal_provider.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EntraApp());
}

class EntraApp extends StatelessWidget {
  const EntraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AttendeeProvider()),
        ChangeNotifierProvider(create: (_) => WithdrawalProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = createRouter(context);

          return MaterialApp.router(
            title: 'Entra',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF7C3AED),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF030712), // gray-950 like entra-web
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF030712),
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF111827), // gray-900
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF374151)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF374151)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                ),
              ),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

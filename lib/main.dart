import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class EntraApp extends StatefulWidget {
  const EntraApp({super.key});

  @override
  State<EntraApp> createState() => _EntraAppState();
}

class _EntraAppState extends State<EntraApp> {
  late final AuthProvider _authProvider;
  late final EventProvider _eventProvider;
  late final AttendeeProvider _attendeeProvider;
  late final WithdrawalProvider _withdrawalProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _eventProvider = EventProvider();
    _attendeeProvider = AttendeeProvider();
    _withdrawalProvider = WithdrawalProvider();
    _router = createRouterWithAuth(_authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();
    _eventProvider.dispose();
    _attendeeProvider.dispose();
    _withdrawalProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _eventProvider),
        ChangeNotifierProvider.value(value: _attendeeProvider),
        ChangeNotifierProvider.value(value: _withdrawalProvider),
      ],
      child: MaterialApp.router(
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
        routerConfig: _router,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'config/environment.dart';
import 'screens/dashboard_screen.dart';
import 'screens/users_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/client_settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/support_tickets_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress debug print messages from flutter_quill in debug mode
  if (kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null &&
          (message.contains('FlutterQuillEmbeds') ||
              message.contains('QuillRawEditor') ||
              message.contains('quill_native_bridge'))) {
        return; // Suppress quill debug messages
      }
      // Print other messages normally
      debugPrintThrottled(message, wrapWidth: wrapWidth);
    };
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: EnvironmentConfig.isProd
                ? 'myblueboard Admin'
                : 'myblueboard Admin - ${EnvironmentConfig.environmentName}',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US')],
            onGenerateRoute: (settings) {
              if (settings.name == '/client-settings') {
                final client = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => ClientSettingsScreen(client: client),
                );
              }
              return null;
            },
            initialRoute: '/',
            routes: {
              '/': (context) => Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.isAuthenticated) {
                    return const DashboardScreen();
                  }
                  return const LoginPage();
                },
              ),
              '/login': (context) => const LoginPage(),
              '/dashboard': (context) => const DashboardScreen(),
              '/users': (context) => const UsersScreen(),
              '/clients': (context) => const ClientsScreen(),
              '/accounts': (context) =>
                  const PlaceholderScreen(title: 'Accounts'),
              '/tickets': (context) => SupportTicketsScreen(),
              '/settings': (context) =>
                  const PlaceholderScreen(title: 'Settings'),
            },
          );
        },
      ),
    );
  }
}

// Placeholder screen for routes not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$title screen coming soon',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

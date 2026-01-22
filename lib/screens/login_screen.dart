import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/environment.dart';
import 'dashboard_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _enableBiometric = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final available = await authProvider.isBiometricAvailable();
    final enabled = await authProvider.isBiometricEnabled();

    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });

    // If biometric is enabled, show biometric prompt
    if (enabled && mounted) {
      _handleBiometricLogin();
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.loginWithBiometric();

    if (mounted) {
      if (success && authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.login(
        _emailController.text,
        _passwordController.text,
        saveBiometric: _enableBiometric,
      );

      if (mounted) {
        if (authProvider.isAuthenticated) {
          // Navigate to dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else if (authProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF001b3f), // #001b3f
                  Color(0xFF004aad), // #004aad
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/mybb_logo.png',
                            height: 60,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.school,
                                size: 60,
                                color: Color(0xFF004aad),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Environment indicator (hidden in production)
                          if (EnvironmentConfig.isDev)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Text(
                                '${EnvironmentConfig.environmentName} Environment',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 32),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Color(0xFF004aad),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Color(0xFF004aad),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xFF004aad),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Biometric toggle (only show if available and not already enabled)
                          if (_biometricAvailable && !_biometricEnabled)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.fingerprint,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Enable Face ID / Touch ID',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _enableBiometric,
                                    onChanged: (value) {
                                      setState(() {
                                        _enableBiometric = value;
                                      });
                                    },
                                    activeColor: Color(0xFF1e88e5),
                                  ),
                                ],
                              ),
                            ),
                          if (_biometricAvailable && !_biometricEnabled)
                            const SizedBox(height: 20),

                          // Biometric login button (only show if enabled)
                          if (_biometricEnabled)
                            OutlinedButton.icon(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _handleBiometricLogin,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white, width: 2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.fingerprint, size: 24),
                              label: const Text(
                                'LOG IN WITH BIOMETRICS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          if (_biometricEnabled) const SizedBox(height: 16),

                          // Login Button
                          ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1e88e5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'LOG IN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Copyright
                          Text(
                            '© ${DateTime.now().year} myblueboard',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

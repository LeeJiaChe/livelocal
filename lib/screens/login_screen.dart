import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../core/config/app_environment.dart';
import '../core/routing/protected_navigation.dart';
import '../core/validation/auth_form_validator.dart';
import '../features/auth/domain/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showError = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _preservePendingOnExit = false;
  bool _navigatingAfterAuth = false;

  InputDecoration _fieldDecoration({
    required IconData prefixIcon,
    required String labelText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.primary,
      ),
      labelText: labelText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
    );
  }

  void _clearError() {
    if (!_showError) {
      return;
    }

    setState(() {
      _showError = false;
      _errorMessage = '';
    });
  }

  void _showAuthError(
    AuthController authController, {
    String fallback = 'Authentication could not be completed.',
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _showError = true;
      _errorMessage = authController.errorMessage ?? fallback;
    });
  }

  void _navigateHome() {
    if (!mounted || _navigatingAfterAuth) {
      return;
    }

    _navigatingAfterAuth = true;
    _preservePendingOnExit = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    });
  }

  void _handleBack() {
    if (!_preservePendingOnExit) {
      context.read<ProtectedNavigation?>()?.clearPending();
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      '/home',
    );
  }

  void _switchToRegister() {
    _preservePendingOnExit = true;

    Navigator.pushReplacementNamed(
      context,
      '/register',
    );
  }

  Future<void> _handleLogin() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final authController = context.read<AuthController>();

    if (authController.isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();
    _clearError();

    final success = await authController.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _navigateHome();
      return;
    }

    _showAuthError(
      authController,
      fallback: 'Invalid email or password. Please try again.',
    );
  }

  Future<void> _handleSocialLogin(
    SocialAuthProvider provider,
  ) async {
    final authController = context.read<AuthController>();

    if (authController.isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();
    _clearError();

    final success = await authController.signInWithSocial(
      provider,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showAuthError(
        authController,
      );
    }
  }

  Widget _socialButton({
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              child: Center(
                child: icon,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    final isSubmitting = authController.isLoading;

    if (authController.isAuthenticated) {
      _navigateHome();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!_preservePendingOnExit) {
          context.read<ProtectedNavigation?>()?.clearPending();
        }

        if (!didPop) {
          Navigator.of(context).pushReplacementNamed(
            '/home',
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: isSubmitting ? null : _handleBack,
          ),
          title: const Text(
            'LiveLocal',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Log in to continue exploring',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_showError) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          autofillHints: const [
                            AutofillHints.email,
                          ],
                          onChanged: (_) => _clearError(),
                          decoration: _fieldDecoration(
                            prefixIcon: Icons.email_outlined,
                            labelText: context.tr(
                              'Email Address',
                            ),
                          ),
                          validator: (value) => context.trNullable(
                            AuthFormValidator.validateEmail(
                              value,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.password,
                          ],
                          onChanged: (_) => _clearError(),
                          onFieldSubmitted: (_) {
                            if (!isSubmitting) {
                              _handleLogin();
                            }
                          },
                          decoration: _fieldDecoration(
                            prefixIcon: Icons.lock_outline,
                            labelText: context.tr(
                              'Password',
                            ),
                            suffixIcon: IconButton(
                              tooltip: context.tr(
                                _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.primary,
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      setState(
                                        () {
                                          _obscurePassword = !_obscurePassword;
                                        },
                                      );
                                    },
                            ),
                          ),
                          validator: (value) => context.trNullable(
                            AuthFormValidator.validateLoginPassword(
                              value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                '/password-reset',
                              );
                            },
                      child: const Text(
                        'Forgot password?',
                      ),
                    ),
                  ),
                  if (context.read<AppConfiguration>().isDemo) ...[
                    const Text(
                      'Demo mode uses the fixed password 123456 and does not contact production services.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _socialButton(
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    label: 'Continue with Google',
                    onPressed: isSubmitting
                        ? null
                        : () {
                            _handleSocialLogin(
                              SocialAuthProvider.google,
                            );
                          },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                      ),
                      TextButton(
                        onPressed: isSubmitting ? null : _switchToRegister,
                        child: const Text(
                          'Sign up',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

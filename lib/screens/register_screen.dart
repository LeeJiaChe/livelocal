import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../core/validation/auth_form_validator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  bool _preservePendingOnExit = false;

  void _handleBack() {
    if (!_preservePendingOnExit) {
      context.read<ProtectedNavigation?>()?.clearPending();
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _switchToLogin() {
    _preservePendingOnExit = true;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _handleRegister() async {
    final currentForm = _formKey.currentState;

    if (currentForm == null || !currentForm.validate()) {
      return;
    }

    final authCtrl = context.read<AuthController>();

    if (authCtrl.isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await authCtrl.register(
      _emailController.text.trim(),
      _passwordController.text,
      _fullNameController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _preservePendingOnExit = true;
      final requiresVerification =
          authCtrl.status == AuthStatus.verificationRequired;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requiresVerification
                ? 'Account created. Check your email to verify it.'
                : 'Account created successfully.',
          ),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authCtrl.errorMessage ??
                'Unable to create account. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<AuthController>().isLoading;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!_preservePendingOnExit) {
          context.read<ProtectedNavigation?>()?.clearPending();
        }
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
                    'Create your account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Join thousands discovering authentic Malaysia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'All new accounts start as tourists. '
                    'Creator applications are available from your '
                    'profile after verification.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ==================================================
                        // FULL NAME
                        // ==================================================

                        TextFormField(
                          controller: _fullNameController,
                          enabled: !isSubmitting,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.name,
                          ],
                          decoration: _fieldDecoration(
                            prefixIcon: Icons.person_outline,
                            labelText: context.tr('Full Name'),
                          ),
                          validator: (value) => context.trNullable(
                            AuthFormValidator.validateFullName(value),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // EMAIL
                        // ==================================================

                        TextFormField(
                          controller: _emailController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          autofillHints: const [
                            AutofillHints.email,
                          ],
                          decoration: _fieldDecoration(
                            prefixIcon: Icons.email_outlined,
                            labelText: context.tr('Email Address'),
                          ),
                          validator: (value) => context.trNullable(
                            AuthFormValidator.validateEmail(value),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // PASSWORD
                        // ==================================================

                        TextFormField(
                          controller: _passwordController,
                          enabled: !isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.newPassword,
                          ],
                          decoration: _fieldDecoration(
                            prefixIcon: Icons.lock_outline,
                            labelText: context.tr('Password'),
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
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                            ),
                          ),
                          validator: (value) => context.trNullable(
                            AuthFormValidator.validateRegisterPassword(value),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // CONFIRM PASSWORD
                        // ==================================================

                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !isSubmitting,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.newPassword,
                          ],
                          onFieldSubmitted: (_) {
                            if (!isSubmitting) {
                              _handleRegister();
                            }
                          },
                          decoration: _fieldDecoration(
                            prefixIcon: Icons.lock_outline,
                            labelText: context.tr('Confirm Password'),
                            suffixIcon: IconButton(
                              tooltip: context.tr(
                                _obscureConfirm
                                    ? 'Show password confirmation'
                                    : 'Hide password confirmation',
                              ),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.primary,
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscureConfirm = !_obscureConfirm;
                                      });
                                    },
                            ),
                          ),
                          validator: (value) {
                            return context.trNullable(
                              AuthFormValidator.validateConfirmPassword(
                                value,
                                _passwordController.text,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ======================================================
                  // CREATE ACCOUNT BUTTON
                  // ======================================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _handleRegister,
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ======================================================
                  // LOGIN LINK
                  // ======================================================

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                      ),
                      TextButton(
                        onPressed: isSubmitting ? null : _switchToLogin,
                        child: const Text(
                          'Log in',
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

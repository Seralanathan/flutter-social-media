// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'auth_provider.dart';
//
// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }
//
// class _AuthScreenState extends State<AuthScreen> {
//   final _key = GlobalKey<FormState>();
//   final _name = TextEditingController(), _mobile = TextEditingController(), _pass = TextEditingController();
//   bool _isLogin = true, _busy = false;
//
//   Future<void> _submit() async {
//     if (!_key.currentState!.validate()) return;
//     setState(() => _busy = true);
//     final auth = context.read<AuthProvider>();
//     String? err;
//     if (_isLogin) {
//       err = await auth.login(_mobile.text.trim(), _pass.text);
//     } else {
//       err = await auth.register(_name.text.trim(), _mobile.text.trim(), _pass.text);
//       if (err == null) {
//         _isLogin = true;
//         ScaffoldMessenger.of(context)
//             .showSnackBar(const SnackBar(content: Text('Registered. Please login.')));
//       }
//     }
//     if (!mounted) return;
//     setState(() => _busy = false);
//     if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Form(
//               key: _key,
//               child: Column(children: [
//                 Text(_isLogin ? 'Welcome back' : 'Create account',
//                     style: Theme.of(context).textTheme.headlineMedium),
//                 const SizedBox(height: 24),
//                 if (!_isLogin)
//                   TextFormField(
//                     controller: _name,
//                     decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
//                     validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
//                   ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _mobile,
//                   keyboardType: TextInputType.phone,
//                   maxLength: 10,
//                   decoration: const InputDecoration(labelText: 'Mobile number', border: OutlineInputBorder()),
//                   validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v ?? '') ? null : 'Enter valid 10-digit number',
//                 ),
//                 TextFormField(
//                   controller: _pass,
//                   obscureText: true,
//                   decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
//                   validator: (v) => (v ?? '').length < 6 ? 'Min 6 characters' : null,
//                 ),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: FilledButton(
//                     onPressed: _busy ? null : _submit,
//                     child: _busy
//                         ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
//                         : Text(_isLogin ? 'Login' : 'Register'),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () => setState(() => _isLogin = !_isLogin),
//                   child: Text(_isLogin ? 'New here? Register' : 'Have an account? Login'),
//                 ),
//               ]),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/exit_dialog.dart';
import 'auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _key = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _pass = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;
  bool _showPassword = false;

  static const Color primary = Color(0xFF6558D3);
  static const Color background = Color(0xFFF4F3FF);

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor:
          success ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_key.currentState!.validate()) return;

    setState(() => _busy = true);

    String? err;
    bool registered = false;

    try {
      final auth = context.read<AuthProvider>();

      if (_isLogin) {
        err = await auth.login(
          _mobile.text.trim(),
          _pass.text,
        );
      } else {
        err = await auth.register(
          _name.text.trim(),
          _mobile.text.trim(),
          _pass.text,
        );

        if (err == null) {
          registered = true;
          _isLogin = true;
          _pass.clear();
        }
      }
    } catch (_) {
      err = 'Something went wrong. Please try again.';
    }

    if (!mounted) return;

    setState(() => _busy = false);

    if (err != null) {
      _showMessage(err);
    } else if (registered) {
      setState(() {});
      _showMessage(
        'Account created successfully! Please login.',
        success: true,
      );
    }
    // On successful login, AuthProvider should update its
    // authentication state or navigate according to your app design.
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _pass.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primary),
      suffixIcon: suffixIcon,
      filled: true,
      // fillColor: background.withValues(alpha: 0.65),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE5E1FA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) confirmExit(context);
        },child: Scaffold(
      backgroundColor: background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAE7FF),
              Color(0xFFF8F7FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      // color: primary.withValues(alpha: 0.10),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          height: 76,
                          width: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8174F5),
                                primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.lock_person_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF24213D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? 'Login to continue to your account'
                            : 'Join us and create your new account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            label: 'Full name',
                            icon: Icons.person_outline,
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Please enter your name'
                              : null,
                        ),
                        const SizedBox(height: 17),
                      ],

                      TextFormField(
                        controller: _mobile,
                        maxLength: 10,
                        decoration: _inputDecoration(
                          label: 'Mobile number',
                          icon: Icons.phone_android_rounded,
                        ).copyWith(
                          counterText: '',
                          hintText: 'Enter 10-digit mobile number',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                            return 'Enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 17),

                      TextFormField(
                        controller: _pass,
                        obscureText: !_showPassword,
                        decoration: _inputDecoration(
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Hide password'
                                : 'Show password',
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!_isLogin && v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            // disabledBackgroundColor:
                            // primary.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                          ),
                          child: _busy
                              ? const SizedBox(
                            height: 23,
                            width: 23,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _isLogin
                                  ? "Don't have an account?"
                                  : 'Already have an account?',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _showPassword = false;
                                _key.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isLogin ? 'Register' : 'Login',
                              style: const TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
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
        ),
      ),
    )
    );
  }
}

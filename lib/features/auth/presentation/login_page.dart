import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isSignUp = false;
  bool _isLoading = false;
  String _error = '';

  // Login fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  // Sign up fields
  final _signUpUsernameController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showSignUpPassword = false;
  bool _showConfirmPassword = false;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _signUpUsernameController.dispose();
    _signUpPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() { _error = ''; });
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Username dan password harus diisi');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).login(
            _usernameController.text,
            _passwordController.text,
          );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _error = 'Username atau password salah');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    setState(() { _error = ''; });
    if (_signUpUsernameController.text.isEmpty ||
        _signUpPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _error = 'Semua field harus diisi');
      return;
    }
    if (_signUpPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Password tidak cocok');
      return;
    }
    if (!_agreeTerms) {
      setState(() => _error = 'Setujui syarat & ketentuan');
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSignUp = false;
        _error = '';
        _signUpUsernameController.clear();
        _signUpPasswordController.clear();
        _confirmPasswordController.clear();
        _agreeTerms = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dibuat! Silakan login.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 400 : 420),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF111827), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSignUp ? _buildSignUpForm() : _buildLoginForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'LOGIN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Color(0xFF111827),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildLabel('Username'),
        const SizedBox(height: 8),
        _buildBorderedInput(controller: _usernameController, hint: 'admin'),
        const SizedBox(height: 20),
        _buildLabel('Password'),
        const SizedBox(height: 8),
        _buildBorderedInput(
          controller: _passwordController,
          hint: '••••••••',
          obscure: !_showPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF6B7280),
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('Forgot Password',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
        ),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF60A5FA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Login'),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(thickness: 2, color: Color(0xFF111827)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? ",
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            GestureDetector(
              onTap: () => setState(() {
                _isSignUp = true;
                _error = '';
              }),
              child: const Text('Sign Up',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Hint: password "123456"',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'SIGN UP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Color(0xFF111827),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        _buildLabel('Username'),
        const SizedBox(height: 8),
        _buildBorderedInput(controller: _signUpUsernameController, hint: 'johndoe'),
        const SizedBox(height: 16),
        _buildLabel('Password'),
        const SizedBox(height: 8),
        _buildBorderedInput(
          controller: _signUpPasswordController,
          hint: '••••••••',
          obscure: !_showSignUpPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _showSignUpPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF6B7280),
            ),
            onPressed: () => setState(() => _showSignUpPassword = !_showSignUpPassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Confirm Password'),
        const SizedBox(height: 8),
        _buildBorderedInput(
          controller: _confirmPasswordController,
          hint: '••••••••',
          obscure: !_showConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF6B7280),
            ),
            onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
              activeColor: const Color(0xFF3B82F6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('I agree to the Terms and Conditions',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF60A5FA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Sign Up'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account? ',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            GestureDetector(
              onTap: () => setState(() {
                _isSignUp = false;
                _error = '';
              }),
              child: const Text('Login',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151)));
  }

  Widget _buildBorderedInput({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        suffixIcon: suffixIcon,
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF111827), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF111827), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
    );
  }
}

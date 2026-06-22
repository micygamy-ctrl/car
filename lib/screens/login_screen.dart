import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('saved_email', _emailController.text.trim());
        } else {
          await prefs.remove('saved_email');
        }
      } else {
        await _authService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      }

      // navigate صريح عشان مش نعتمد على Stream بس
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.toString()),
                style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('من فضلك أدخل بريدك الإلكتروني أولاً',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال رابط إعادة تعيين كلمة المرور على بريدك! 📧',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.toString()),
                style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) return 'البريد الإلكتروني غير مسجل';
    if (error.contains('wrong-password')) return 'كلمة المرور غير صحيحة';
    if (error.contains('email-already-in-use')) return 'البريد الإلكتروني مسجل بالفعل';
    if (error.contains('weak-password')) return 'كلمة المرور ضعيفة جداً';
    if (error.contains('invalid-email')) return 'البريد الإلكتروني غير صحيح';
    if (error.contains('network-request-failed')) return 'تحقق من اتصالك بالإنترنت';
    return 'حدث خطأ، حاول مرة أخرى';
  }

  void _toggleMode() {
    _animationController.reset();
    setState(() => _isLogin = !_isLogin);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // اللوجو
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'مساعد السيارة الذكي',
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'تتبع سيارتك بذكاء 🚗',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),

                // الفورم
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(38),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // تبويب تسجيل دخول / إنشاء حساب
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!_isLogin) _toggleMode();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isLogin
                                            ? const Color(0xFF1E88E5)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'تسجيل دخول',
                                        style: GoogleFonts.cairo(
                                          color: _isLogin ? Colors.white : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_isLogin) _toggleMode();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isLogin
                                            ? const Color(0xFF1E88E5)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'إنشاء حساب',
                                        style: GoogleFonts.cairo(
                                          color: !_isLogin ? Colors.white : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // حقل الاسم (إنشاء حساب فقط)
                          if (!_isLogin) ...[
                            _buildTextField(
                              controller: _nameController,
                              label: 'الاسم الكامل',
                              hint: 'أدخل اسمك',
                              icon: Icons.person,
                              validator: (v) => v!.isEmpty ? 'من فضلك أدخل اسمك' : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // حقل الإيميل
                          _buildTextField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            hint: 'example@email.com',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v!.isEmpty) return 'من فضلك أدخل بريدك الإلكتروني';
                              if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // حقل كلمة المرور
                          _buildTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            hint: '••••••••',
                            icon: Icons.lock,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v!.isEmpty) return 'من فضلك أدخل كلمة المرور';
                              if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                              return null;
                            },
                          ),

                          // تأكيد كلمة المرور (إنشاء حساب فقط)
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'تأكيد كلمة المرور',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                              validator: (v) {
                                if (v!.isEmpty) return 'من فضلك أكد كلمة المرور';
                                if (v != _passwordController.text)
                                  return 'كلمة المرور غير متطابقة';
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Remember Me و Forgot Password
                          if (_isLogin)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: _forgotPassword,
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xFF1E88E5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'تذكرني',
                                      style: GoogleFonts.cairo(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) =>
                                          setState(() => _rememberMe = v!),
                                      activeColor: const Color(0xFF1E88E5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // زرار الدخول
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'تسجيل الدخول' : 'إنشاء الحساب',
                                      style: GoogleFonts.cairo(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}
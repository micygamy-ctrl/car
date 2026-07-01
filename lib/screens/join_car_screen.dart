import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/role_service.dart';

class JoinCarScreen extends StatefulWidget {
  const JoinCarScreen({super.key});

  @override
  State<JoinCarScreen> createState() => _JoinCarScreenState();
}

class _JoinCarScreenState extends State<JoinCarScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final carName =
          await RoleService().joinByCode(_codeController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم الانضمام لسيارة "$carName" بنجاح! 🎉',
              style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text('انضم لسيارة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF1E88E5).withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key,
                          color: Color(0xFF1E88E5), size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'اطلب كود الدعوة من مالك السيارة وادخله هنا',
                          style: GoogleFonts.cairo(
                              color: const Color(0xFF1E88E5), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('كود الدعوة',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'XXXXXX',
                    hintStyle: GoogleFonts.cairo(
                        color: Colors.grey.withAlpha(120),
                        letterSpacing: 8,
                        fontSize: 28),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 6) {
                      return 'الكود يجب أن يكون 6 خانات';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _join,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      _isLoading ? 'جاري الانضمام...' : 'انضم الآن',
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/car_model.dart';
import '../services/role_service.dart';

class ManageDriversScreen extends StatelessWidget {
  final CarModel car;
  const ManageDriversScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final roleService = RoleService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text('إدارة السواقين',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // زرار إنشاء كود دعوة
            Container(
              width: double.infinity,
              color: const Color(0xFF1E88E5),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: ElevatedButton.icon(
                onPressed: () => _generateCode(context, roleService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_link),
                label: Text('إنشاء كود دعوة جديد',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            // قائمة السواقين
            Expanded(
              child: StreamBuilder<List<CarMember>>(
                stream: roleService.getCarMembers(car.carId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final members = snapshot.data ?? [];

                  if (members.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 80,
                              color: Colors.grey.withAlpha(100)),
                          const SizedBox(height: 16),
                          Text(
                            'مفيش سواقين لسه',
                            style: GoogleFonts.cairo(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أنشئ كود دعوة وابعته للسواق',
                            style: GoogleFonts.cairo(
                                color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: members.length,
                    itemBuilder: (context, i) {
                      final m = members[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF1E88E5).withAlpha(30),
                            child: Text(
                              m.name.isNotEmpty
                                  ? m.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFF1E88E5),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            m.name.isNotEmpty ? m.name : m.email,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.name.isNotEmpty)
                                Text(m.email,
                                    style: GoogleFonts.cairo(
                                        color: Colors.grey, fontSize: 12)),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF43A047).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'سواق',
                                  style: GoogleFonts.cairo(
                                      color: const Color(0xFF43A047),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            tooltip: 'إزالة السواق',
                            onPressed: () =>
                                _confirmRemove(context, roleService, m),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateCode(
      BuildContext context, RoleService roleService) async {
    try {
      final code = await roleService.generateInviteCode(
        car.carId,
        '${car.make} ${car.model}',
      );
      if (context.mounted) {
        _showCodeDialog(context, code);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ، حاول مرة أخرى',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('كود الدعوة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ابعت الكود ده للسواق عشان ينضم لسيارتك',
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF1E88E5).withAlpha(80)),
                ),
                child: Text(
                  code,
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5),
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'صالح لمدة 24 ساعة',
                style:
                    GoogleFonts.cairo(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم نسخ الكود! 📋',
                      style: GoogleFonts.cairo()),
                  backgroundColor: const Color(0xFF43A047),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ));
              },
              icon: const Icon(Icons.copy),
              label: Text('نسخ', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text('تمام',
                  style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, RoleService roleService,
      CarMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('إزالة السواق',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text(
            'هل تريد إزالة "${member.name.isNotEmpty ? member.name : member.email}" من السيارة؟',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('إزالة',
                  style: GoogleFonts.cairo(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await roleService.removeMember(car.carId, member.userId);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('حدث خطأ، حاول مرة أخرى', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }
}

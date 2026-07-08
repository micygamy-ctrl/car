import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════
//  بيانات ثابتة: قوالب الصيانة الجاهزة + تصنيفات الخدمة
//  (منقولة من add_service_screen.dart بدون أي تغيير في المحتوى)
// ═══════════════════════════════════════════════════════

class MaintenanceTemplate {
  final String title;
  final IconData icon;
  final int intervalKm;
  final int intervalDays;

  const MaintenanceTemplate({
    required this.title,
    required this.icon,
    required this.intervalKm,
    required this.intervalDays,
  });
}

const List<MaintenanceTemplate> maintenanceTemplates = [
  MaintenanceTemplate(
    title: 'تغيير فلتر الزيت',
    icon: Icons.filter_alt,
    intervalKm: 5000,
    intervalDays: 180,
  ),
  MaintenanceTemplate(
    title: 'تغيير زيت الموتور',
    icon: Icons.oil_barrel,
    intervalKm: 5000,
    intervalDays: 180,
  ),
  MaintenanceTemplate(
    title: 'تغيير فلتر الهواء',
    icon: Icons.air,
    intervalKm: 10000,
    intervalDays: 365,
  ),
  MaintenanceTemplate(
    title: 'تغيير فلتر التكييف',
    icon: Icons.ac_unit,
    intervalKm: 10000,
    intervalDays: 365,
  ),
  MaintenanceTemplate(
    title: 'تغيير بوجيهات',
    icon: Icons.bolt,
    intervalKm: 30000,
    intervalDays: 730,
  ),
  MaintenanceTemplate(
    title: 'تغيير تيل الفرامل',
    icon: Icons.car_repair,
    intervalKm: 20000,
    intervalDays: 730,
  ),
  MaintenanceTemplate(
    title: 'تغيير زيت الفتيس',
    icon: Icons.settings,
    intervalKm: 60000,
    intervalDays: 1095,
  ),
  MaintenanceTemplate(
    title: 'تغيير سائل التبريد',
    icon: Icons.water_drop,
    intervalKm: 40000,
    intervalDays: 730,
  ),
  MaintenanceTemplate(
    title: 'تغيير البطارية',
    icon: Icons.battery_charging_full,
    intervalKm: 0,
    intervalDays: 730,
  ),
  MaintenanceTemplate(
    title: 'تغيير/ الإطارات',
    icon: Icons.album,
    intervalKm: 50000,
    intervalDays: 1460,
  ),
  MaintenanceTemplate(
    title: 'تغيير زيت الباور',
    icon: Icons.settings,
    intervalKm: 60000,
    intervalDays: 1095,
  ),
  MaintenanceTemplate(
    title: 'تغيير فلتر الوقود',
    icon: Icons.settings,
    intervalKm: 60000,
    intervalDays: 1095,
  ),
];

const List<Map<String, dynamic>> serviceCategories = [
  {
    'value': 'maintenance',
    'label': 'صيانة',
    'icon': Icons.build,
    'color': const Color(0xFF43A047),
  },
  {
    'value': 'insurance',
    'label': 'تأمين',
    'icon': Icons.shield,
    'color': const Color(0xFF1E88E5),
  },
  {
    'value': 'license',
    'label': 'رخصة',
    'icon': Icons.credit_card,
    'color': const Color(0xFF8E24AA),
  },
  {
    'value': 'violation',
    'label': 'مخالفة',
    'icon': Icons.warning,
    'color': const Color(0xFFE53935),
  },
  {
    'value': 'wash',
    'label': 'غسيل',
    'icon': Icons.local_car_wash,
    'color': const Color(0xFF00ACC1),
  },
  {
    'value': 'inspection',
    'label': 'فحص',
    'icon': Icons.fact_check,
    'color': const Color(0xFFFB8C00),
  },
  {
    'value': 'emergency',
    'label': 'طوارئ',
    'icon': Icons.emergency,
    'color': const Color(0xFFD81B60),
  },
  {
    'value': 'other',
    'label': 'أخرى',
    'icon': Icons.more_horiz,
    'color': const Color(0xFF757575),
  },
];
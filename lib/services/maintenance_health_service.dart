import 'dart:math';

import 'package:flutter/material.dart';

import '../models/car_model.dart';
import '../models/maintenance_item_model.dart';
import '../models/maintenance_log_model.dart';

enum MaintenanceUrgency { overdue, dueSoon, ok }

class MaintenanceHealthItem {
  final String title;
  final String detail;
  final IconData icon;
  final MaintenanceUrgency urgency;
  final double progress;
  final int priority;

  const MaintenanceHealthItem({
    required this.title,
    required this.detail,
    required this.icon,
    required this.urgency,
    required this.progress,
    required this.priority,
  });

  bool get needsAttention => urgency != MaintenanceUrgency.ok;

  Color get color {
    switch (urgency) {
      case MaintenanceUrgency.overdue:
        return const Color(0xFFE53935);
      case MaintenanceUrgency.dueSoon:
        return const Color(0xFFFB8C00);
      case MaintenanceUrgency.ok:
        return const Color(0xFF43A047);
    }
  }

  String get statusLabel {
    switch (urgency) {
      case MaintenanceUrgency.overdue:
        return 'مستحق الآن';
      case MaintenanceUrgency.dueSoon:
        return 'قريب';
      case MaintenanceUrgency.ok:
        return 'تمام';
    }
  }
}

class CarHealthSnapshot {
  final int score;
  final List<MaintenanceHealthItem> items;

  const CarHealthSnapshot({required this.score, required this.items});

  int get overdueCount =>
      items.where((item) => item.urgency == MaintenanceUrgency.overdue).length;

  int get dueSoonCount =>
      items.where((item) => item.urgency == MaintenanceUrgency.dueSoon).length;

  int get attentionCount => overdueCount + dueSoonCount;

  String get statusText {
    if (overdueCount > 0) return 'محتاج تدخل';
    if (dueSoonCount > 0) return 'تابع قريب';
    return 'الحالة مستقرة';
  }

  Color get statusColor {
    if (overdueCount > 0) return const Color(0xFFE53935);
    if (dueSoonCount > 0) return const Color(0xFFFB8C00);
    return const Color(0xFF43A047);
  }
}

class MaintenanceHealthService {
  static const double dueSoonKm = 500;
  static const int dueSoonDays = 30;

  CarHealthSnapshot evaluate({
    required CarModel car,
    required List<ServiceLogModel> serviceLogs,
    List<MaintenanceItemModel> maintenanceItems = const [],
  }) {
    final items = <MaintenanceHealthItem>[
      _oilItem(car),
      if (maintenanceItems.isNotEmpty)
        ..._maintenanceItems(car, maintenanceItems)
      else
        ..._scheduledServiceItems(car, serviceLogs),
    ];

    items.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.title.compareTo(b.title);
    });

    final overdue = items
        .where((item) => item.urgency == MaintenanceUrgency.overdue)
        .length;
    final dueSoon = items
        .where((item) => item.urgency == MaintenanceUrgency.dueSoon)
        .length;
    final score = max(0, 100 - (overdue * 25) - (dueSoon * 10));

    return CarHealthSnapshot(score: score, items: items);
  }

  List<MaintenanceHealthItem> _maintenanceItems(
    CarModel car,
    List<MaintenanceItemModel> items,
  ) {
    return items.map((item) {
      final kmRemaining = item.nextDueOdometer == null
          ? null
          : item.nextDueOdometer! - car.currentOdometer;
      final daysRemaining = item.nextDueDate == null
          ? null
          : item.nextDueDate!.difference(DateTime.now()).inDays;

      var urgency = MaintenanceUrgency.ok;
      var priority = 2;
      if ((kmRemaining != null && kmRemaining <= 0) ||
          (daysRemaining != null && daysRemaining < 0)) {
        urgency = MaintenanceUrgency.overdue;
        priority = 0;
      } else if ((kmRemaining != null && kmRemaining <= dueSoonKm) ||
          (daysRemaining != null && daysRemaining <= dueSoonDays)) {
        urgency = MaintenanceUrgency.dueSoon;
        priority = 1;
      }

      return MaintenanceHealthItem(
        title: item.title,
        detail: _itemDetailFor(kmRemaining, daysRemaining),
        icon: _iconFor(item.category),
        urgency: urgency,
        progress: _itemProgressFor(car, item),
        priority: priority,
      );
    }).toList();
  }

  MaintenanceHealthItem _oilItem(CarModel car) {
    final driven = car.currentOdometer - car.lastOilChangeOdometer;
    final remaining = car.oilChangeInterval - driven;
    final progress = car.oilChangeInterval <= 0
        ? 1.0
        : (driven / car.oilChangeInterval).clamp(0.0, 1.0);

    if (remaining <= 0) {
      return MaintenanceHealthItem(
        title: 'زيت الموتور',
        detail: 'متأخر ${remaining.abs().toStringAsFixed(0)} كم',
        icon: Icons.oil_barrel,
        urgency: MaintenanceUrgency.overdue,
        progress: progress,
        priority: 0,
      );
    }

    if (remaining <= dueSoonKm) {
      return MaintenanceHealthItem(
        title: 'زيت الموتور',
        detail: 'باقي ${remaining.toStringAsFixed(0)} كم',
        icon: Icons.oil_barrel,
        urgency: MaintenanceUrgency.dueSoon,
        progress: progress,
        priority: 1,
      );
    }

    return MaintenanceHealthItem(
      title: 'زيت الموتور',
      detail: 'باقي ${remaining.toStringAsFixed(0)} كم',
      icon: Icons.oil_barrel,
      urgency: MaintenanceUrgency.ok,
      progress: progress,
      priority: 2,
    );
  }

  List<MaintenanceHealthItem> _scheduledServiceItems(
    CarModel car,
    List<ServiceLogModel> logs,
  ) {
    final scheduledLogs = logs.where((log) {
      return log.nextDueOdometer != null || log.expiryDate != null;
    }).toList();

    final latestByTitle = <String, ServiceLogModel>{};
    for (final log in scheduledLogs) {
      final key = '${log.category}:${log.title.trim()}'.toLowerCase();
      final current = latestByTitle[key];
      if (current == null || log.date.isAfter(current.date)) {
        latestByTitle[key] = log;
      }
    }

    return latestByTitle.values.map((log) {
      final kmRemaining = log.nextDueOdometer == null
          ? null
          : log.nextDueOdometer! - car.currentOdometer;
      final daysRemaining = log.expiryDate == null
          ? null
          : log.expiryDate!.difference(DateTime.now()).inDays;

      var urgency = MaintenanceUrgency.ok;
      var priority = 2;
      if ((kmRemaining != null && kmRemaining <= 0) ||
          (daysRemaining != null && daysRemaining < 0)) {
        urgency = MaintenanceUrgency.overdue;
        priority = 0;
      } else if ((kmRemaining != null && kmRemaining <= dueSoonKm) ||
          (daysRemaining != null && daysRemaining <= dueSoonDays)) {
        urgency = MaintenanceUrgency.dueSoon;
        priority = 1;
      }

      return MaintenanceHealthItem(
        title: log.title,
        detail: _detailFor(log, kmRemaining, daysRemaining),
        icon: _iconFor(log.category),
        urgency: urgency,
        progress: _progressFor(car, log),
        priority: priority,
      );
    }).toList();
  }

  String _detailFor(
    ServiceLogModel log,
    double? kmRemaining,
    int? daysRemaining,
  ) {
    if (kmRemaining != null) {
      if (kmRemaining <= 0) {
        return 'متأخر ${kmRemaining.abs().toStringAsFixed(0)} كم';
      }
      return 'باقي ${kmRemaining.toStringAsFixed(0)} كم';
    }

    if (daysRemaining != null) {
      if (daysRemaining < 0) return 'متأخر ${daysRemaining.abs()} يوم';
      if (daysRemaining == 0) return 'ينتهي اليوم';
      return 'باقي $daysRemaining يوم';
    }

    return log.category;
  }

  String _itemDetailFor(double? kmRemaining, int? daysRemaining) {
    if (kmRemaining != null) {
      if (kmRemaining <= 0) {
        return 'متأخر ${kmRemaining.abs().toStringAsFixed(0)} كم';
      }
      return 'باقي ${kmRemaining.toStringAsFixed(0)} كم';
    }

    if (daysRemaining != null) {
      if (daysRemaining < 0) return 'متأخر ${daysRemaining.abs()} يوم';
      if (daysRemaining == 0) return 'ينتهي اليوم';
      return 'باقي $daysRemaining يوم';
    }

    return 'لا يوجد ميعاد قادم';
  }

  double _progressFor(CarModel car, ServiceLogModel log) {
    if (log.odometer == null || log.nextDueOdometer == null) return 0;
    final interval = log.nextDueOdometer! - log.odometer!;
    if (interval <= 0) return 1;
    final driven = car.currentOdometer - log.odometer!;
    return (driven / interval).clamp(0.0, 1.0);
  }

  double _itemProgressFor(CarModel car, MaintenanceItemModel item) {
    if (item.lastServiceOdometer == null || item.nextDueOdometer == null) {
      return 0;
    }
    final interval = item.nextDueOdometer! - item.lastServiceOdometer!;
    if (interval <= 0) return 1;
    final driven = car.currentOdometer - item.lastServiceOdometer!;
    return (driven / interval).clamp(0.0, 1.0);
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'insurance':
        return Icons.shield;
      case 'license':
        return Icons.credit_card;
      case 'violation':
        return Icons.warning;
      case 'wash':
        return Icons.local_car_wash;
      case 'inspection':
        return Icons.fact_check;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.build;
    }
  }
}

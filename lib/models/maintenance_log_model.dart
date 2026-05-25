class MaintenanceLogModel {
  final String logId;
  final String carId;
  final String category;
  final String title;
  final DateTime date;
  final double odometer;
  final double cost;
  final String? garage;
  final String status;
  final double? nextDueOdometer;
  final DateTime? nextDueDate;
  final String? receiptUrl;
  final String? notes;
  final bool reminderSent;

  MaintenanceLogModel({
    required this.logId,
    required this.carId,
    required this.category,
    required this.title,
    required this.date,
    required this.odometer,
    required this.cost,
    this.garage,
    required this.status,
    this.nextDueOdometer,
    this.nextDueDate,
    this.receiptUrl,
    this.notes,
    required this.reminderSent,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'carId': carId,
      'category': category,
      'title': title,
      'date': date,
      'odometer': odometer,
      'cost': cost,
      'garage': garage,
      'status': status,
      'nextDueOdometer': nextDueOdometer,
      'nextDueDate': nextDueDate,
      'receiptUrl': receiptUrl,
      'notes': notes,
      'reminderSent': reminderSent,
    };
  }

  factory MaintenanceLogModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceLogModel(
      logId: map['logId'] ?? '',
      carId: map['carId'] ?? '',
      category: map['category'] ?? 'other',
      title: map['title'] ?? '',
      date: (map['date'] as dynamic).toDate(),
      odometer: (map['odometer'] ?? 0).toDouble(),
      cost: (map['cost'] ?? 0).toDouble(),
      garage: map['garage'],
      status: map['status'] ?? 'done',
      nextDueOdometer: map['nextDueOdometer']?.toDouble(),
      nextDueDate: map['nextDueDate'] != null
          ? (map['nextDueDate'] as dynamic).toDate()
          : null,
      receiptUrl: map['receiptUrl'],
      notes: map['notes'],
      reminderSent: map['reminderSent'] ?? false,
    );
  }
}
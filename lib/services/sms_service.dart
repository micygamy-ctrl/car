import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsFuelResult {
  final double amountEGP;
  final String merchantName;
  final DateTime date;
  final String rawSms;
  final String bankName;
  final String smsId;

  SmsFuelResult({
    required this.amountEGP,
    required this.merchantName,
    required this.date,
    required this.rawSms,
    required this.bankName,
    required this.smsId,
  });
}

class SmsService {
  final SmsQuery _query = SmsQuery();

  static const List<String> _fuelKeywords = [
    'محطة', 'وقود', 'بنزين', 'ديزل', 'سولار', 'بترول',
    'total', 'misr petroleum', 'petrol', 'fuel', 'gas station',
    'petroleum', 'taqa', 'watanya', 'shell', 'mobil',
  ];

  Future<bool> requestPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<SmsFuelResult>> checkNewFuelSms() async {
    final granted = await requestPermissions();
    if (!granted) return [];

    final prefs = await SharedPreferences.getInstance();
    final processedIds = prefs.getStringList('processed_sms_ids') ?? [];

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 50,
    );

    final results = <SmsFuelResult>[];

    for (final msg in messages) {
      final id = msg.id?.toString() ?? '';
      if (id.isEmpty || processedIds.contains(id)) continue;

      final body = msg.body ?? '';
      final sender = msg.sender ?? '';
      final result = _parseSms(id, body, sender, msg.date ?? DateTime.now());

      if (result != null) results.add(result);
    }

    return results;
  }

  Future<void> markSmsAsProcessed(String smsId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('processed_sms_ids') ?? [];
    if (!ids.contains(smsId)) {
      ids.add(smsId);
      if (ids.length > 500) ids.removeRange(0, ids.length - 500);
      await prefs.setStringList('processed_sms_ids', ids);
    }
  }

  SmsFuelResult? _parseSms(String id, String body, String sender, DateTime date) {
    final lower = body.toLowerCase();

    final isFuel = _fuelKeywords.any((k) => lower.contains(k.toLowerCase()));
    if (!isFuel) return null;

    if (!_containsDebitKeyword(lower)) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    final merchant = _extractMerchant(body) ?? 'محطة وقود';
    final bank = _detectBank(sender, body);

    return SmsFuelResult(
      amountEGP: amount,
      merchantName: merchant,
      date: date,
      rawSms: body,
      bankName: bank,
      smsId: id,
    );
  }

  bool _containsDebitKeyword(String lower) {
    const words = [
      'خصم', 'سحب', 'دفع', 'مدين', 'تم الخصم',
      'purchase', 'debit', 'used for', 'payment', 'pos', 'charged',
    ];
    return words.any((w) => lower.contains(w));
  }

  double? _extractAmount(String body) {
    final patterns = [
      RegExp(r'EGP\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:جنيه|ج\.م|egp)', caseSensitive: false),
      RegExp(r'مبلغ\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'amount[:\s]*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (v != null && v > 5 && v < 10000) return v;
      }
    }
    return null;
  }

  String? _extractMerchant(String body) {
    final patterns = [
      RegExp(r'at\s+([A-Za-z0-9\s\-&]+?)(?:\s+on|\s+\d|$)', caseSensitive: false),
      RegExp(r'لدى\s+(.+?)(?:\s+بتاريخ|$)'),
      RegExp(r'merchant[:\s]+([A-Za-z0-9\s]+)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        final name = m.group(1)?.trim();
        if (name != null && name.length > 2 && name.length < 50) return name;
      }
    }
    for (final kw in _fuelKeywords) {
      if (body.toLowerCase().contains(kw.toLowerCase())) return kw;
    }
    return null;
  }

  String _detectBank(String sender, String body) {
    final s = (sender + body).toLowerCase();
    if (s.contains('cib')) return 'CIB';
    if (s.contains('nbe') || s.contains('أهلي')) return 'البنك الأهلي';
    if (s.contains('banque misr') || s.contains('بنك مصر')) return 'بنك مصر';
    if (s.contains('hsbc')) return 'HSBC';
    if (s.contains('qnb')) return 'QNB';
    if (s.contains('faisal')) return 'بنك فيصل';
    if (s.contains('aaib')) return 'العربي الأفريقي';
    return 'البنك';
  }
}

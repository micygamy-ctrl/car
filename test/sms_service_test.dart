import 'package:flutter_test/flutter_test.dart';

import 'package:car/services/sms_service.dart';

void main() {
  group('SmsService.parseFuelSms', () {
    test('extracts fuel purchase amount and bank from an English bank SMS', () {
      final result = SmsService.parseFuelSms(
        'sms-1',
        'Your card was used for purchase EGP 650.50 at Total gas station on 01/07.',
        'CIB',
        DateTime(2026, 7, 1),
      );

      expect(result, isNotNull);
      expect(result!.amountEGP, 650.50);
      expect(result.bankName, 'CIB');
      expect(result.smsId, 'sms-1');
    });

    test('ignores non-fuel debit messages', () {
      final result = SmsService.parseFuelSms(
        'sms-2',
        'Your card was used for purchase EGP 220.00 at supermarket.',
        'CIB',
        DateTime(2026, 7, 1),
      );

      expect(result, isNull);
    });
  });
}

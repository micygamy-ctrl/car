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

    test('بيتعرف على رسالة خصم عربي فيها مبلغ ومحطة ويستخرج اسم المحطة',
        () {
      final result = SmsService.parseFuelSms(
        'sms-3',
        'تم الخصم مبلغ 300.00 جنيه من حسابك لدى محطة وقود توتال بتاريخ 01/07',
        'بنك مصر',
        DateTime(2026, 7, 1),
      );

      expect(result, isNotNull);
      expect(result!.amountEGP, 300.00);
      expect(result.bankName, 'بنك مصر');
      expect(result.merchantName, contains('محطة'));
    });

    test('بيرفض الرسالة لو فيها كلمة وقود بس من غير كلمة خصم/دفع', () {
      // رسالة تذكيرية بس، مش عملية دفع فعلية
      final result = SmsService.parseFuelSms(
        'sms-4',
        'Reminder: fill up at Shell station soon',
        'CIB',
        DateTime(2026, 7, 1),
      );

      expect(result, isNull);
    });

    test('بيرفض المبلغ لو أقل من أو يساوي 5 جنيه (غالبًا رقم مش مبلغ حقيقي)',
        () {
      final result = SmsService.parseFuelSms(
        'sms-5',
        'Your card was used for purchase EGP 3.00 at Shell station.',
        'CIB',
        DateTime(2026, 7, 1),
      );

      expect(result, isNull);
    });

    test('بيرفض المبلغ لو 10000 جنيه أو أكتر (غالبًا خطأ في القراءة)', () {
      final result = SmsService.parseFuelSms(
        'sms-6',
        'Your card was used for purchase EGP 15000.00 at Shell station.',
        'CIB',
        DateTime(2026, 7, 1),
      );

      expect(result, isNull);
    });

    test('لما مفيش اسم محطة واضح، بيرجع اسم كلمة الوقود اللي لقاها كـ fallback',
        () {
      final result = SmsService.parseFuelSms(
        'sms-7',
        'Fuel purchase debit EGP 200.00 done',
        'CIB',
        DateTime(2026, 7, 1),
      );

      expect(result, isNotNull);
      expect(result!.merchantName, isNotEmpty);
    });

    group('التعرف على اسم البنك', () {
      final cases = <String, String>{
        'CIB': 'CIB',
        'NBE': 'البنك الأهلي',
        'أهلي': 'البنك الأهلي',
        'Banque Misr': 'بنك مصر',
        'HSBC': 'HSBC',
        'QNB': 'QNB',
        'Faisal Islamic Bank': 'بنك فيصل',
        'AAIB': 'العربي الأفريقي',
        'Some Random Sender': 'البنك', // غير معروف → افتراضي
      };

      cases.forEach((sender, expectedBank) {
        test('$sender → $expectedBank', () {
          final result = SmsService.parseFuelSms(
            'sms-bank',
            'Your card was used for purchase EGP 100.00 at Shell station.',
            sender,
            DateTime(2026, 7, 1),
          );

          expect(result, isNotNull);
          expect(result!.bankName, expectedBank);
        });
      });
    });
  });
}
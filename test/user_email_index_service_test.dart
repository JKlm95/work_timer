import 'package:flutter_test/flutter_test.dart';
import 'package:work_timer/services/user_email_index_service.dart';

void main() {
  test('emailLowerIndexKey normalizuje i odrzuca puste', () {
    expect(UserEmailIndexService.emailLowerIndexKey('  A@B.C  '), 'a@b.c');
    expect(UserEmailIndexService.emailLowerIndexKey(null), isNull);
    expect(UserEmailIndexService.emailLowerIndexKey(''), isNull);
    expect(UserEmailIndexService.emailLowerIndexKey('   '), isNull);
  });
}

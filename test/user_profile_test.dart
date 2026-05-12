import 'package:flutter_test/flutter_test.dart';
import 'package:work_timer/models/user_profile.dart';

void main() {
  test('composeDisplayName łączy i trimuje', () {
    expect(
      UserProfile.composeDisplayName('  Jan  ', '  Kowalski  '),
      'Jan Kowalski',
    );
    expect(UserProfile.composeDisplayName('Anna', ''), 'Anna');
    expect(UserProfile.composeDisplayName('', 'Nowak'), 'Nowak');
    expect(UserProfile.composeDisplayName('  ', '  '), '');
  });

  test('hasAnyName', () {
    expect(UserProfile.hasAnyName('', ''), isFalse);
    expect(UserProfile.hasAnyName(' ', ''), isFalse);
    expect(UserProfile.hasAnyName('A', ''), isTrue);
    expect(UserProfile.hasAnyName('', 'B'), isTrue);
  });
}

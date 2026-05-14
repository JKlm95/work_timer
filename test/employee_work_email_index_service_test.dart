import 'package:flutter_test/flutter_test.dart';

import 'package:work_timer/models/workspace.dart';
import 'package:work_timer/services/employee_work_email_index_service.dart';
import 'package:work_timer/utils/project_field_utils.dart';

void main() {
  group('normalizeEmployeeWorkEmail', () {
    test('trim + lower + walidacja', () {
      expect(
        normalizeEmployeeWorkEmail('  User@Example.COM '),
        'user@example.com',
      );
      expect(normalizeEmployeeWorkEmail('not-an-email'), isNull);
      expect(normalizeEmployeeWorkEmail('a@b'), isNull);
    });
  });

  group('normalizeEmployeeWorkEmailDomain', () {
    test('z pola lub z work email', () {
      expect(
        normalizeEmployeeWorkEmailDomain(' Sub.DOMAIN ', workEmail: null),
        'sub.domain',
      );
      expect(
        normalizeEmployeeWorkEmailDomain(null, workEmail: 'u@Firma.PL'),
        'firma.pl',
      );
    });
  });

  group('EmployeeWorkEmailIndexService.buildDesiredEmailWorkspaceMap', () {
    final t0 = DateTime(2024, 1, 1);
    final t1 = DateTime(2024, 2, 1);

    test('shared + poprawny e-mail → workspaceId na mapie', () {
      final map = EmployeeWorkEmailIndexService.buildDesiredEmailWorkspaceMap([
        Workspace(
          id: 'w1',
          name: 'A',
          createdAt: t0,
          updatedAt: t1,
          isSharedWithEmployer: true,
          companyName: 'C',
          companySlug: 'c',
          employeeWorkEmail: 'Kuba@Firma.pl',
          employeeWorkEmailDomain: 'firma.pl',
        ),
      ]);
      expect(map['kuba@firma.pl'], ['w1']);
    });

    test('prywatny lub brak e-maila → brak wpisu', () {
      final map = EmployeeWorkEmailIndexService.buildDesiredEmailWorkspaceMap([
        Workspace(
          id: 'w1',
          name: 'A',
          createdAt: t0,
          updatedAt: t1,
          isSharedWithEmployer: false,
          employeeWorkEmail: 'x@y.pl',
        ),
        Workspace(
          id: 'w2',
          name: 'B',
          createdAt: t0,
          updatedAt: t1,
          isSharedWithEmployer: true,
        ),
      ]);
      expect(map, isEmpty);
    });

    test('zmiana e-maila: dwa workspace na jednym adresie', () {
      final map = EmployeeWorkEmailIndexService.buildDesiredEmailWorkspaceMap([
        Workspace(
          id: 'w2',
          name: 'B',
          createdAt: t0,
          updatedAt: t1,
          isSharedWithEmployer: true,
          employeeWorkEmail: 'same@corp.com',
          employeeWorkEmailDomain: 'corp.com',
        ),
        Workspace(
          id: 'w1',
          name: 'A',
          createdAt: t0,
          updatedAt: t1,
          isSharedWithEmployer: true,
          employeeWorkEmail: 'same@corp.com',
          employeeWorkEmailDomain: 'corp.com',
        ),
      ]);
      expect(map['same@corp.com'], ['w1', 'w2']);
    });
  });
}

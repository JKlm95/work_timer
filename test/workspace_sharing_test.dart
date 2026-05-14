import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:work_timer/models/workspace.dart';
import 'package:work_timer/utils/project_field_utils.dart';
import 'package:work_timer/utils/workspace_firestore_write.dart';

void main() {
  group('normalizeLinkedEmployerEmails', () {
    test('trim, lower-case, dedupe, kolejność pierwszego wystąpienia', () {
      expect(
        normalizeLinkedEmployerEmails([
          '  Boss@Corp.com ',
          'boss@corp.com',
          'Other@X.io',
        ]),
        ['boss@corp.com', 'other@x.io'],
      );
    });
  });

  group('resolveCompanySlugForSave', () {
    test('ręczny slug wygrywa', () {
      expect(
        resolveCompanySlugForSave(
          slugField: 'My-Slug',
          companyNameField: 'Ignored Inc',
          persistedSlug: 'old',
        ),
        'my-slug',
      );
    });

    test('pusty slug zachowuje persisted zamiast przeliczać z nazwy', () {
      expect(
        resolveCompanySlugForSave(
          slugField: '   ',
          companyNameField: 'Totally New Company Name',
          persistedSlug: 'acme',
        ),
        'acme',
      );
    });

    test('bez persisted — slug z nazwy firmy', () {
      expect(
        resolveCompanySlugForSave(
          slugField: '',
          companyNameField: 'Acme LLC',
          persistedSlug: null,
        ),
        'acme-llc',
      );
    });
  });

  group('workspaceFirestoreMergeWrite', () {
    final t0 = DateTime(2024, 1, 1);
    final t1 = DateTime(2024, 6, 1);

    test('prywatny: usuwa pola sharingu (FieldValue.delete)', () {
      final w = Workspace(
        id: 'w1',
        name: 'Projekt',
        createdAt: t0,
        updatedAt: t1,
        isSharedWithEmployer: false,
        companyName: 'Should not stay',
        companySlug: 'ghost',
        employeeWorkEmail: 'x@y.com',
        employeeWorkEmailDomain: 'y.com',
        linkedEmployerEmails: const ['a@b.com'],
      );
      final m = workspaceFirestoreMergeWrite(w);
      expect(m['isSharedWithEmployer'], isFalse);
      expect(m['companyName'], isA<FieldValue>());
      expect(m['companySlug'], isA<FieldValue>());
      expect(m['employeeWorkEmail'], isA<FieldValue>());
      expect(m['employeeWorkEmailDomain'], isA<FieldValue>());
      expect(m['linkedEmployerEmails'], isA<FieldValue>());
    });

    test(
      'udostępniony: usuwa legacy linkedEmployerEmails (FieldValue.delete)',
      () {
        final w = Workspace(
          id: 'w1',
          name: 'Projekt',
          createdAt: t0,
          updatedAt: t1,
          isSharedWithEmployer: true,
          companyName: 'Corp',
          companySlug: 'corp',
          employeeWorkEmail: 'me@corp.com',
          employeeWorkEmailDomain: 'corp.com',
          linkedEmployerEmails: const ['legacy@x.com'],
        );
        final m = workspaceFirestoreMergeWrite(w);
        expect(m['isSharedWithEmployer'], isTrue);
        expect(m['linkedEmployerEmails'], isA<FieldValue>());
        expect(m['companySlug'], 'corp');
      },
    );
  });

  group('Workspace.fromJson linkedEmployerEmails', () {
    test('parsuje i normalizuje', () {
      final w = Workspace.fromJson({
        'id': 'x',
        'name': 'N',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-02T00:00:00.000',
        'linkedEmployerEmails': ['A@B.COM', ' a@b.com ', 'c@d'],
      });
      expect(w.linkedEmployerEmails, ['a@b.com', 'c@d']);
    });
  });

  group('Workspace.fromJson employeeWorkEmail', () {
    test('lower-case', () {
      final w = Workspace.fromJson({
        'id': 'x',
        'name': 'N',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-02T00:00:00.000',
        'employeeWorkEmail': '  User@EXAMPLE.com ',
      });
      expect(w.employeeWorkEmail, 'user@example.com');
    });
  });
}

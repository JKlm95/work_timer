import 'billing_currency.dart';
import '../utils/project_field_utils.dart';

class Workspace {
  Workspace({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.companyName,
    this.companySlug,
    this.employeeWorkEmail,
    this.employeeWorkEmailDomain,
    this.colorHex,
    this.hourlyRate,
    this.currencyCode,
    this.isSharedWithEmployer = false,
    this.linkedEmployerEmails = const [],
  });

  static const String defaultId = 'default';

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  final String? companyName;
  final String? companySlug;
  final String? employeeWorkEmail;

  /// Zapisane przy zapisie (z maila) — można też wyliczyć przez [effectiveEmailDomain].
  final String? employeeWorkEmailDomain;

  /// Kolor wyświetlania projektu, np. `#4CAF50`.
  final String? colorHex;
  final double? hourlyRate;

  /// Kod waluty rozliczenia: PLN/EUR/USD/GBP.
  final String? currencyCode;
  final bool isSharedWithEmployer;

  /// **Legacy (tylko odczyt z Firestore):** lista e-maili pracodawców — mobile nie zapisuje ani nie pokazuje w UI.
  final List<String> linkedEmployerEmails;

  String? get effectiveEmailDomain =>
      employeeWorkEmailDomain ?? extractEmailDomain(employeeWorkEmail);

  factory Workspace.defaultWorkspace() {
    final now = DateTime.now();
    return Workspace(
      id: defaultId,
      name: 'Domyslny',
      createdAt: now,
      updatedAt: now,
      currencyCode: BillingCurrency.defaultCode,
    );
  }

  Workspace copyWith({
    String? name,
    DateTime? updatedAt,
    bool? isArchived,
    String? companyName,
    String? companySlug,
    String? employeeWorkEmail,
    String? employeeWorkEmailDomain,
    String? colorHex,
    double? hourlyRate,
    String? currencyCode,
    bool? isSharedWithEmployer,
    List<String>? linkedEmployerEmails,
  }) {
    return Workspace(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      companyName: companyName ?? this.companyName,
      companySlug: companySlug ?? this.companySlug,
      employeeWorkEmail: employeeWorkEmail ?? this.employeeWorkEmail,
      employeeWorkEmailDomain:
          employeeWorkEmailDomain ?? this.employeeWorkEmailDomain,
      colorHex: colorHex ?? this.colorHex,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      currencyCode: currencyCode ?? this.currencyCode,
      isSharedWithEmployer: isSharedWithEmployer ?? this.isSharedWithEmployer,
      linkedEmployerEmails: linkedEmployerEmails ?? this.linkedEmployerEmails,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isArchived': isArchived,
    if (companyName != null) 'companyName': companyName,
    if (companySlug != null) 'companySlug': companySlug,
    if (employeeWorkEmail != null) 'employeeWorkEmail': employeeWorkEmail,
    if (employeeWorkEmailDomain != null)
      'employeeWorkEmailDomain': employeeWorkEmailDomain,
    if (colorHex != null) 'colorHex': colorHex,
    if (hourlyRate != null) 'hourlyRate': hourlyRate,
    if (currencyCode != null) 'currencyCode': currencyCode,
    'isSharedWithEmployer': isSharedWithEmployer,
    'linkedEmployerEmails': linkedEmployerEmails,
  };

  Map<String, dynamic> toFirestore() {
    final m = <String, dynamic>{
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isArchived': isArchived,
      'isSharedWithEmployer': isSharedWithEmployer,
    };
    if (companyName != null) m['companyName'] = companyName;
    if (companySlug != null) m['companySlug'] = companySlug;
    if (employeeWorkEmail != null) m['employeeWorkEmail'] = employeeWorkEmail;
    if (employeeWorkEmailDomain != null) {
      m['employeeWorkEmailDomain'] = employeeWorkEmailDomain;
    }
    if (colorHex != null) m['colorHex'] = colorHex;
    if (hourlyRate != null) m['hourlyRate'] = hourlyRate;
    if (currencyCode != null) m['currencyCode'] = currencyCode;
    if (linkedEmployerEmails.isNotEmpty) {
      m['linkedEmployerEmails'] = linkedEmployerEmails;
    }
    return m;
  }

  factory Workspace.fromJson(Map<String, dynamic> json) {
    double? rate(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    List<String> emails(dynamic v) {
      if (v is! List) return const [];
      final raw = v.whereType<String>();
      return normalizeLinkedEmployerEmails(raw);
    }

    DateTime parsed(String key, String fallback) {
      return DateTime.parse(json[key] as String? ?? fallback);
    }

    final nowIso = DateTime.now().toIso8601String();
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Workspace',
      createdAt: parsed('createdAt', nowIso),
      updatedAt: parsed('updatedAt', json['createdAt'] as String? ?? nowIso),
      isArchived: json['isArchived'] as bool? ?? false,
      companyName: json['companyName'] as String?,
      companySlug: normalizeCompanySlug(json['companySlug'] as String?),
      employeeWorkEmail: normalizeEmployeeWorkEmail(
        json['employeeWorkEmail'] as String?,
      ),
      employeeWorkEmailDomain: normalizeEmployeeWorkEmailDomain(
        json['employeeWorkEmailDomain'] as String?,
        workEmail: json['employeeWorkEmail'] as String?,
      ),
      colorHex: json['colorHex'] as String?,
      hourlyRate: rate(json['hourlyRate']),
      currencyCode: BillingCurrency.normalizeOrNull(
        json['currencyCode'] as String?,
      ),
      isSharedWithEmployer: json['isSharedWithEmployer'] as bool? ?? false,
      linkedEmployerEmails: emails(json['linkedEmployerEmails']),
    );
  }
}

/// Slug firmy: małe litery, cyfry, myślniki; pusty → null.
String? normalizeCompanySlug(String? input) {
  if (input == null) return null;
  final trimmed = input.trim().toLowerCase();
  if (trimmed.isEmpty) return null;
  final buf = StringBuffer();
  for (var i = 0; i < trimmed.length; i++) {
    final c = trimmed.codeUnitAt(i);
    final ch = trimmed[i];
    if ((c >= 0x30 && c <= 0x39) || (c >= 0x61 && c <= 0x7a) || ch == '-') {
      buf.write(ch);
    } else if (ch == ' ' || ch == '_' || ch == '.') {
      buf.write('-');
    }
  }
  var s = buf.toString().replaceAll(RegExp(r'-+'), '-');
  if (s.startsWith('-')) s = s.substring(1);
  if (s.endsWith('-')) s = s.substring(0, s.length - 1);
  return s.isEmpty ? null : s;
}

/// Domena z adresu e-mail (np. `user@acme.com` → `acme.com`), pusty → null.
String? extractEmailDomain(String? email) {
  if (email == null) return null;
  final at = email.trim().lastIndexOf('@');
  if (at <= 0 || at >= email.trim().length - 1) return null;
  final domain = email.trim().substring(at + 1).toLowerCase();
  return domain.isEmpty ? null : domain;
}

/// Prosty walidator adresu służbowego (UI + indeks).
bool isValidEmployeeWorkEmailFormat(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return false;
  final lower = s.toLowerCase();
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(lower);
}

/// Trim + lower-case; `null` gdy pusty lub niepoprawny format.
String? normalizeEmployeeWorkEmail(String? raw) {
  if (raw == null) return null;
  final t = raw.trim().toLowerCase();
  if (t.isEmpty) return null;
  if (!isValidEmployeeWorkEmailFormat(t)) return null;
  return t;
}

/// Domena zapisana przy workspace (spójnie z częścią po `@`).
String? normalizeEmployeeWorkEmailDomain(String? domain, {String? workEmail}) {
  final d = domain?.trim().toLowerCase();
  if (d != null && d.isNotEmpty) return d;
  final em = normalizeEmployeeWorkEmail(workEmail);
  return extractEmailDomain(em);
}

/// E-maile kont pracodawców / panelu: trim, lower-case, bez duplikatów (kolejność zachowana).
List<String> normalizeLinkedEmployerEmails(Iterable<String> raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final s in raw) {
    final t = s.trim().toLowerCase();
    if (t.isEmpty || seen.contains(t)) continue;
    seen.add(t);
    out.add(t);
  }
  return out;
}

/// Slug firmy przy zapisie: ręczny slug > zapisany wcześniej (stabilność) > wyliczenie z nazwy.
String? resolveCompanySlugForSave({
  required String slugField,
  required String companyNameField,
  required String? persistedSlug,
}) {
  final manual = normalizeCompanySlug(slugField);
  if (manual != null) return manual;
  final persisted = normalizeCompanySlug(persistedSlug);
  if (persisted != null) return persisted;
  return normalizeCompanySlug(companyNameField);
}

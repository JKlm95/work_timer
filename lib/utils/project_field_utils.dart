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

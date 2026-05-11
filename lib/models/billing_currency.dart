/// Kody ISO używane w projekcie (bez przeliczników — sumy per waluta).
class BillingCurrency {
  BillingCurrency._();

  static const String pln = 'PLN';
  static const String eur = 'EUR';
  static const String usd = 'USD';
  static const String gbp = 'GBP';

  static const List<String> supportedCodes = [pln, eur, usd, gbp];

  static String? normalizeOrNull(String? raw) {
    if (raw == null) return null;
    final u = raw.trim().toUpperCase();
    if (u.isEmpty) return null;
    return supportedCodes.contains(u) ? u : null;
  }

  static const String defaultCode = pln;
}

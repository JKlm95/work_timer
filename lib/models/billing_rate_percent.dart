/// Procent stawki godzinowej liczony do szacunku rozliczeń (np. nadgodziny 150%, L4 80%).
const List<int> kBillingRatePercentOptions = [50, 80, 100, 150, 200];

int normalizeBillingRatePercent(int? value) {
  if (value == null) return 100;
  return kBillingRatePercentOptions.contains(value) ? value : 100;
}

int parseBillingRatePercent(dynamic raw) {
  if (raw == null) return 100;
  if (raw is int) return normalizeBillingRatePercent(raw);
  if (raw is num) return normalizeBillingRatePercent(raw.toInt());
  return 100;
}

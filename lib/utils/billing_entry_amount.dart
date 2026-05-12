import '../models/billing_currency.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';

/// Kwota dla pojedynczego wpisu (stawka × czas), tylko gdy rozliczalna praca.
double? billableAmountForEntry(WorkEntry entry, Workspace workspace) {
  if (!entry.countsTowardEarningsEstimate) return null;
  final rate = workspace.hourlyRate;
  if (rate == null || rate <= 0) return null;
  final hours = entry.duration.inMicroseconds / Duration.microsecondsPerHour;
  return hours * rate * (entry.billingRatePercent / 100.0);
}

String formatMoneyLine(
  Workspace workspace,
  double amount,
  String formattedNumber,
) {
  final code =
      BillingCurrency.normalizeOrNull(workspace.currencyCode) ??
      BillingCurrency.defaultCode;
  return '$formattedNumber $code';
}

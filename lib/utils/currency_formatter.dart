class CurrencyFormatter {
  static const Map<String, String> currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
  };

  static String getSymbol(String code) {
    return currencySymbols[code] ?? '₹';
  }

  static String format(double amount, {String currencyCode = 'INR'}) {
    final symbol = getSymbol(currencyCode);
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    String formattedNumber;
    if (currencyCode == 'JPY') {
      formattedNumber = absAmount.round().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    } else {
      final parts = absAmount.toStringAsFixed(2).split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      formattedNumber = '$intPart.${parts[1]}';
    }

    final result = '$symbol$formattedNumber';
    return isNegative ? '-$result' : result;
  }
}

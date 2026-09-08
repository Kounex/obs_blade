/// Price parsing / formatting helpers shared by the ASC and Play sides.

/// Parses a price string like `24.99` into Play's `Money` shape
/// (USD unless [currencyCode] is given).
///
/// Throws [FormatException] on anything that is not `\d+(\.\d{1,2})?`.
Map<String, Object?> moneyFromDecimal(
  String price, {
  String currencyCode = 'USD',
}) {
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(price.trim());
  if (match == null) {
    throw FormatException(
      'Invalid price "$price" — expected e.g. 24.99',
      price,
    );
  }
  final units = match.group(1)!;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final nanos = fraction.isEmpty ? 0 : int.parse(fraction) * 10000000;
  return {'currencyCode': currencyCode, 'units': units, 'nanos': nanos};
}

/// Normalizes a price string for comparison against ASC price-point
/// `customerPrice` values (which come back as e.g. `"24.99"` / `"25"`).
String normalizePrice(String price) {
  final money = moneyFromDecimal(price);
  final units = int.parse(money['units'] as String);
  final nanos = money['nanos'] as int;
  if (nanos == 0) return '$units';
  final cents = nanos ~/ 10000000;
  return '$units.${cents.toString().padLeft(2, '0')}';
}

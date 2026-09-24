class Money implements Comparable<Money> {
  const Money.fromCents(this.cents);

  static const zero = Money.fromCents(0);
  static const _maxSafeCents = 9007199254740991;
  static final _pattern = RegExp(r'^-?(0|[1-9]\d*)(?:\.(\d{1,2}))?$');

  final int cents;

  factory Money.parse(String input, {bool allowNegative = true}) {
    final value = input.trim();
    final match = _pattern.firstMatch(value);
    if (match == null) {
      throw const FormatException('Usa un importe con máximo dos decimales.');
    }
    final negative = value.startsWith('-');
    if (negative && !allowNegative) {
      throw const FormatException('El importe debe ser mayor que cero.');
    }
    final unsigned = negative ? value.substring(1) : value;
    final parts = unsigned.split('.');
    final whole = int.parse(parts[0]);
    final fraction = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
    final cents = whole * 100 + int.parse(fraction);
    if (cents > _maxSafeCents) {
      throw const FormatException(
          'El importe supera el límite seguro del dispositivo.');
    }
    if (!allowNegative && cents <= 0) {
      throw const FormatException('El importe debe ser mayor que cero.');
    }
    return Money.fromCents(negative ? -cents : cents);
  }

  Money operator +(Money other) => Money.fromCents(cents + other.cents);

  Money operator -(Money other) => Money.fromCents(cents - other.cents);

  String toDecimalString() {
    final absolute = cents.abs();
    final sign = cents < 0 ? '-' : '';
    return '$sign${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  }

  String format({String currency = 'MXN'}) =>
      '$currency \$${toDecimalString()}';

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;
}

Map<String, Money> splitEqually(Money total, Iterable<String> participantIds) {
  final ids = participantIds.toSet().toList()..sort();
  if (total.cents <= 0 || ids.isEmpty || total.cents < ids.length) {
    throw const FormatException(
      'El total debe asignar al menos un centavo a cada participante.',
    );
  }
  final base = total.cents ~/ ids.length;
  final remainder = total.cents % ids.length;
  return {
    for (var index = 0; index < ids.length; index++)
      ids[index]: Money.fromCents(base + (index < remainder ? 1 : 0)),
  };
}

class Money {
  const Money._(this.cents);

  final int cents;

  factory Money.fromPesos(String value) {
    final parts = value.split('.');
    final pesos = int.parse(parts.first);
    final cents = parts.length > 1 ? int.parse(parts[1].padRight(2, '0').substring(0, 2)) : 0;
    return Money._(pesos * 100 + cents);
  }

  Money operator +(Money other) => Money._(cents + other.cents);

  Money operator -(Money other) => Money._(cents - other.cents);

  String format() => '\$${(cents / 100).toStringAsFixed(2)}';
}

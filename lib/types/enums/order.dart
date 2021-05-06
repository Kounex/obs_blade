enum Order {
  Ascending,
  Descending,
}

extension FilterOrderFunctions on Order {
  String get text => const {
        Order.Ascending: 'Asc.',
        Order.Descending: 'Desc.',
      }[this]!;
}

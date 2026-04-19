enum TransactionType {
  income,
  expense;

  String get label => name[0].toUpperCase() + name.substring(1);

  static TransactionType fromString(String value) =>
      TransactionType.values.firstWhere((e) => e.name == value);
}

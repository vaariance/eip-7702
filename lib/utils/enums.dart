part of '../eip7702.dart';

enum TransactionSpeed {
  fast(75),
  slow(25),
  normal(50);

  final int value;
  const TransactionSpeed(this.value);
}

enum TransactionType {
  eip1559(0x02),
  eip7702(0x04);

  final int value;
  const TransactionType(this.value);
}

part of '../eip7702.dart';

/// Represents a relative gas price multiplier used when estimating or
/// adjusting fees for a transaction.
///
/// These values do not correspond to specific gas prices; instead they
/// provide a convenient qualitative scale (`slow`, `normal`, `fast`)
/// that builders or clients may use to bias fee calculations.
///
/// For example, a higher value such as [TransactionSpeed.fast] may
/// increase a max fee estimate, while [TransactionSpeed.slow] may
/// decrease it.
enum TransactionSpeed {
  fast(75),
  slow(25),
  normal(50);

  final int value;
  const TransactionSpeed(this.value);
}

// Represents supported Ethereum typed transaction formats used by
/// this library.
///
/// The enum maps high-level transaction categories to their canonical
/// type byte as defined in the Ethereum protocol:
///
///  - `0x02` – EIP-1559 dynamic-fee transactions
///  - `0x04` – EIP-7702 delegated account transactions
///
/// This is primarily used when constructing serialized transactions
/// or selecting the appropriate encoding strategy.
///
/// See also:
///  - EIP-1559: https://eips.ethereum.org/EIPS/eip-1559
///  - EIP-7702: https://eips.ethereum.org/EIPS/eip-7702
enum TransactionType {
  eip1559(0x02),
  eip7702(0x04);

  final int value;
  const TransactionType(this.value);
}

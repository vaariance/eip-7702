part of '../eip7702.dart';

/// Converts a hex-encoded address string to an [EthereumAddress] instance.
///
/// This utility function wraps [EthereumAddress.fromHex] for convenience.
///
/// Parameters:
///  - [hexAddress] — the Ethereum address as a hex string (with or without
///    '0x' prefix).
///
/// Returns an [EthereumAddress] object.
///
/// ### Example
/// ```dart
/// final address = toEthAddress('0x1234...');
/// ```
EthereumAddress toEthAddress(HexString hexAddress) {
  return EthereumAddress.fromHex(hexAddress);
}

/// The zero address (0x0000000000000000000000000000000000000000).
///
/// This constant is used in EIP-7702 operations to represent:
///  - Revocation target: when revoking a delegation, the EOA delegates to
///    this address to clear the implementation.
///  - Default/null address: representing an empty or unset address value.
const HexString zeroAddress = "0x0000000000000000000000000000000000000000";

/// Extension on [HexString] providing convenient address conversion utilities.
extension StringX on HexString {
  /// Converts this hex string to an [EthereumAddress].
  ///
  /// This is a convenience getter that wraps [toEthAddress], allowing for
  /// more fluent address conversions in method chains.
  ///
  /// ### Example
  /// ```dart
  /// final address = '0x1234...'.ethAddress;
  /// ```
  EthereumAddress get ethAddress => toEthAddress(this);
}

part of '../../builder.dart';

/// Base interface for components that require an [Eip7702Context].
///
/// Classes that perform signing, authorization construction, gas/nonce
/// resolution, or transaction building should implement this interface
/// to gain access to the underlying context.
///
/// This interface ensures that all EIP-7702 builders and utilities operate with
/// a shared context containing network configuration, RPC access, and signing
/// parameters.
///
/// See also:
///  - [Eip7702Context] – holds RPC client, chain ID, and delegate
///    implementation address.
///  - [Eip7702Common] – a shared mixin implementing common RPC helpers.
///
/// Learn more about EIP-7702:
/// https://eips.ethereum.org/EIPS/eip-7702
abstract class Eip7702Base {
  Eip7702Context get ctx;
}
